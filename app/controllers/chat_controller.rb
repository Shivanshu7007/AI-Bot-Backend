# require "net/http"
# require "uri"

# class ChatController < ApplicationController
#   skip_before_action :verify_authenticity_token
#   protect_from_forgery with: :null_session

#   # GET /chat
#   def index
#     render file: Rails.root.join("public", "chat", "index.html")
#   end

#   # POST /chat
#   def create
#     product_id = params[:product_id]
#     question   = params[:question]

#     if product_id.blank? || question.blank?
#       return render json: { reply: "Missing parameters." }, status: :bad_request
#     end

#     uri = URI.parse("http://127.0.0.1:8000/ask")
#     http = Net::HTTP.new(uri.host, uri.port)
#     http.read_timeout = 120

#     request = Net::HTTP::Post.new(uri.request_uri, {
#       "Content-Type" => "application/json",
#       "x-api-key"    => ENV["SERVICE_API_KEY"]
#     })

#     request.body = {
#       product_id: product_id.to_i,
#       question: question
#     }.to_json

#     response = http.request(request)

#     unless response.code.to_i == 200
#       Rails.logger.error response.body
#       return render json: { reply: "⚠️ Chat failed. Please try again." }
#     end

#     # ✅ IMPORTANT: Do NOT parse JSON
#     reply_text = response.body.to_s.strip

#     render json: { reply: reply_text }

#   rescue => e
#     Rails.logger.error e.message
#     render json: { reply: "⚠️ Chat failed. Please try again." }
#   end
# end
require "net/http"
require "uri"

class ChatController < ApplicationController
  skip_before_action :verify_authenticity_token
  protect_from_forgery with: :null_session

  # --------------------------------
  # POST /chat
  # --------------------------------
  def create
    product_id = params[:product_id]
    question   = params[:question]

    if product_id.blank? || question.blank?
      return render json: { reply: "Missing parameters." }, status: :bad_request
    end

    uri = URI.parse("http://127.0.0.1:8000/ask")
    http = Net::HTTP.new(uri.host, uri.port)
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
