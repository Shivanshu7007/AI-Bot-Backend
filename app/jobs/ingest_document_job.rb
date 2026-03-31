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

  MAX_FILE_SIZE = 20.megabytes

  def perform(product_id, blob_id)
    product = Product.find_by(id: product_id)
    return unless product

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob

    if blob.byte_size > MAX_FILE_SIZE
      Rails.logger.warn "[IngestDocumentJob] File too large (#{blob.byte_size} bytes) for product #{product_id}. Skipping."
      return
    end

    Rails.logger.info "[IngestDocumentJob] Starting ingest for product #{product_id}"

    file_content = blob.download
    filename     = blob.filename.to_s.downcase

    Rails.logger.info "[IngestDocumentJob] File size: #{file_content.bytesize} bytes"

    text = extract_text(file_content, filename)

    if text.blank?
      Rails.logger.warn "[IngestDocumentJob] No text extracted from #{filename}"
      return
    end

    send_to_python(product.id, text)

    Rails.logger.info "[IngestDocumentJob] Ingest success for product #{product.id}"

  rescue StandardError => e
    Rails.logger.error "[IngestDocumentJob] Failed for product #{product_id}: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise e
  end

  # ==========================
  # TEXT EXTRACTION
  # ==========================

  def extract_text(raw, filename)
    case
    when filename.end_with?(".pdf")
      reader = PDF::Reader.new(StringIO.new(raw))
      reader.pages.map(&:text).join("\n")

    when filename.end_with?(".docx")
      doc = Docx::Document.open(StringIO.new(raw))
      doc.paragraphs.map(&:text).join("\n")

    when filename.end_with?(".txt")
      raw.force_encoding("UTF-8")

    when filename.end_with?(".yaml", ".yml")
      parsed = YAML.safe_load(raw, permitted_classes: [Date, Time], aliases: false)
      parsed.to_s

    when filename.end_with?(".json")
      parsed = JSON.parse(raw)
      parsed.to_s

    when filename.end_with?(".doc")
      Rails.logger.warn "❌ .doc format not supported. Please upload .docx"
      ""

    else
      Rails.logger.warn "Unsupported file format: #{filename}"
      ""
    end

  rescue => e
    Rails.logger.error "Parsing error: #{e.message}"
    ""
  end

  # ==========================
  # SEND TO PYTHON
  # ==========================

  def send_to_python(product_id, text)
    python_url = ENV.fetch("PYTHON_API_URL")
    api_key    = ENV.fetch("SERVICE_API_KEY")

    uri = URI.parse("#{python_url}/ingest")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 180

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
      Rails.logger.error "[IngestDocumentJob] Python ingest error (#{response.code}): #{response.body}"
      raise "Python ingest failed with status #{response.code}"
    end
  end
end