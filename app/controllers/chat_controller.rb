require "net/http"
require "uri"

class ChatController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session

  def create
    product_id = params[:product_id]
    question   = params[:question]

    if product_id.blank? || question.blank?
      return render json: { reply: "Missing parameters." }, status: :bad_request
    end

    python_url = ENV.fetch("PYTHON_API_URL")

    uri = URI.parse("#{python_url}/ask")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.read_timeout = 120

    request = Net::HTTP::Post.new(uri.request_uri, {
      "Content-Type" => "application/json",
      "x-api-key"    => ENV["SERVICE_API_KEY"]
    })

    request.body = {
      product_id: product_id.to_i,
      question: question
    }.to_json

    response = http.request(request)

    unless response.code.to_i == 200
      Rails.logger.error response.body
      return render json: { reply: "⚠️ Chat failed. Please try again." }
    end

    render json: { reply: response.body.to_s.strip }

  rescue => e
    Rails.logger.error e.message
    render json: { reply: "⚠️ Server error. Please try again." }
  end
end