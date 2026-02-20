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

    file_content = blob.download
    filename     = blob.filename.to_s.downcase

    text = extract_text(file_content, filename)
    return if text.blank?

    send_to_python(product.id, text)

    Rails.logger.info "✅ Ingest success for product #{product.id}"

  rescue => e
    Rails.logger.error "IngestDocumentJob failed: #{e.message}"
  end

  # ====================================================
  # UNIVERSAL FILE PARSER
  # ====================================================

  def extract_text(raw, filename)

    case
    when filename.end_with?(".pdf")
      parse_pdf(raw)

    when filename.end_with?(".docx")
      parse_docx(raw)

    when filename.end_with?(".txt")
      raw.force_encoding("UTF-8")

    when filename.end_with?(".yaml", ".yml")
      parse_yaml(raw)

    else
      Rails.logger.error "Unsupported file type: #{filename}"
      ""
    end

  rescue => e
    Rails.logger.error "File parsing error: #{e.message}"
    ""
  end

  # ---------------- PDF ----------------

  def parse_pdf(raw)
    reader = PDF::Reader.new(StringIO.new(raw))
    reader.pages.map(&:text).join("\n")
  rescue => e
    Rails.logger.error "PDF parsing failed: #{e.message}"
    ""
  end

  # ---------------- DOCX ----------------

  def parse_docx(raw)
    doc = Docx::Document.open(StringIO.new(raw))
    doc.paragraphs.map(&:text).join("\n")
  rescue => e
    Rails.logger.error "DOCX parsing failed: #{e.message}"
    ""
  end

  # ---------------- YAML ----------------

  def parse_yaml(raw)
    yaml = YAML.safe_load(raw)
    yaml.to_s
  rescue => e
    Rails.logger.error "YAML parsing failed: #{e.message}"
    ""
  end

  # ====================================================
  # SEND TO FASTAPI
  # ====================================================

  def send_to_python(product_id, text)

    python_url = ENV.fetch("PYTHON_API_URL", "http://localhost:8000")

    uri = URI.parse("#{python_url}/ingest")

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 10
    http.read_timeout = 120

    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "x-api-key" => ENV["SERVICE_API_KEY"]
    })

    request.body = {
      product_id: product_id,
      text: text
    }.to_json

    response = http.request(request)

    unless response.code.to_i == 200
      raise "Python ingest failed: #{response.body}"
    end
  end
end
