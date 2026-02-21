require "net/http"
require "uri"
require "json"
require "pdf-reader"
require "docx"
require "yaml"
require "stringio"

class IngestDocumentJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 5

  def perform(product_id, blob_id)
    product = Product.find_by(id: product_id)
    return unless product

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob

    Rails.logger.info "🔄 Starting ingest for product #{product_id}"

    file_content = blob.download
    filename     = blob.filename.to_s.downcase

    Rails.logger.info "📦 File size: #{file_content.bytesize}"

    text = extract_text(file_content, filename)

    if text.blank?
      Rails.logger.warn "⚠️ No text extracted from #{filename}"
      return
    end

    send_to_python(product.id, text)

    Rails.logger.info "✅ Ingest success for product #{product.id}"

  rescue => e
    Rails.logger.error "❌ IngestDocumentJob failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise e
  end

  def extract_text(raw, filename)
    case
    when filename.end_with?(".pdf")
      reader = PDF::Reader.new(StringIO.new(raw))
      reader.pages.map(&:text).join("\n")

    when filename.end_with?(".docx")
      doc = Docx::Document.open(StringIO.new(raw))
      doc.paragraphs.map(&:text).join("\n")

    else
      ""
    end
  rescue => e
    Rails.logger.error "Parsing error: #{e.message}"
    ""
  end

  def send_to_python(product_id, text)
    python_url = ENV.fetch("PYTHON_API_URL")
    api_key    = ENV.fetch("SERVICE_API_KEY")

    uri = URI.parse("#{python_url}/ingest")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"

    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "x-api-key"    => api_key
    })

    request.body = {
      product_id: product_id,
      text: text
    }.to_json

    response = http.request(request)

    unless response.code.to_i == 200
      Rails.logger.error "FastAPI error: #{response.body}"
      raise "Python ingest failed"
    end
  end
end