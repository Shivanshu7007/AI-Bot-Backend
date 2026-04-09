require "net/http"
require "uri"

class ChatController < ApplicationController
  skip_before_action :verify_authenticity_token

  MAX_QUESTION_LENGTH = 1000

  def create
    product_id = params[:product_id]
    question   = params[:question]

    if product_id.blank? || question.blank?
      return render json: { reply: "Missing parameters." }, status: :bad_request
    end

    if question.length > MAX_QUESTION_LENGTH
      return render json: { reply: "Question too long. Please keep it under #{MAX_QUESTION_LENGTH} characters." }, status: :bad_request
    end

    pid = product_id.to_i
    unless Product.exists?(pid)
      return render json: { reply: "Product not found." }, status: :not_found
    end

    python_url = ENV.fetch("PYTHON_API_URL")
    uri = URI.parse("#{python_url}/ask")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl    = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 120

    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "x-api-key"    => ENV.fetch("SERVICE_API_KEY")
    })

    history = params[:history] || []
    request.body = { product_id: pid, question: question.strip, history: history }.to_json

    response = http.request(request)

    unless response.code.to_i == 200
      Rails.logger.error "[ChatController] Python error (#{response.code}) for product=#{pid}: #{response.body}"
      return render json: { reply: "Chat failed. Please try again." }
    end

    body = response.body.to_s.strip
    begin
      parsed = JSON.parse(body)
      if parsed["status"] == "no_knowledge_base"
        return render json: { status: "no_knowledge_base" }
      end
    rescue JSON::ParserError
      # Not JSON — plain text reply, fall through
    end

    render json: { reply: body }

  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "[ChatController] Timeout for product=#{pid}: #{e.message}"
    render json: { reply: "The request timed out. Please try again." }
  rescue StandardError => e
    Rails.logger.error "[ChatController] Error for product=#{pid}: #{e.message}"
    render json: { reply: "Server error. Please try again." }
  end
end