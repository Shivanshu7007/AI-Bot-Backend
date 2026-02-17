require "net/http"
require "uri"
require "json"

class IngestDocumentJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 5

  def perform(product_id, blob_id)
    product = Product.find_by(id: product_id)
    return unless product

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob

    text = extract_text_from_pdf(blob.download)
    return if text.blank?

    uri = URI.parse("http://127.0.0.1:8000/ingest")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 60

    request = Net::HTTP::Post.new(uri.request_uri)

    # 🔐 ADD API KEY HERE
    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "x-api-key" => ENV["SERVICE_API_KEY"]
    })

    request.body = {
      product_id: product.id,
      text: text
    }.to_json

    response = http.request(request)

    unless response.code.to_i == 200
      raise "Python ingest failed: #{response.body}"
    end

    Rails.logger.info "✅ Ingest success for product #{product.id}"
  end

  private

  def extract_text_from_pdf(file)
    require "pdf-reader"
    reader = PDF::Reader.new(StringIO.new(file))
    reader.pages.map(&:text).join("\n")
  rescue => e
    Rails.logger.error "PDF parsing failed: #{e.message}"
    ""
  end
end
