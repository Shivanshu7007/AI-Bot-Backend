require "net/http"
require "uri"
require "json"
require "pdf-reader"
require "docx"
require "yaml"
require "stringio"
require "open-uri"

class IngestDocumentJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 5

  def perform(product_id, blob_id)
    product = Product.find_by(id: product_id)
    return unless product

    blob = ActiveStorage::Blob.find_by(id: blob_id)
    return unless blob

    Rails.logger.info "🔄 Starting ingest for product #{product_id}"

    # ✅ IMPORTANT FIX FOR CLOUDINARY
    file_content = URI.open(blob.url).read
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
    io = StringIO.new(raw)
    reader = PDF::Reader.new(io)

    text = reader.pages.map(&:text).join("\n")

    if text.blank?
      Rails.logger.warn "⚠️ PDF has no extractable text (possibly scanned PDF)"
    end

    text

  rescue PDF::Reader::MalformedPDFError => e
    Rails.logger.error "Malformed PDF: #{e.message}"
    ""

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
    yaml = YAML.safe_load(raw, permitted_classes: [Date, Time], aliases: true)
    yaml.to_s

  rescue => e
    Rails.logger.error "YAML parsing failed: #{e.message}"
    ""
  end

  # ====================================================
  # SEND TO FASTAPI
  # ====================================================

  def send_to_python(product_id, text)
    python_url = ENV.fetch("PYTHON_API_URL")
    api_key    = ENV.fetch("SERVICE_API_KEY")

    uri = URI.parse("#{python_url}/ingest")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 120

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