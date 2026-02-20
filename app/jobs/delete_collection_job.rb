require "net/http"
require "uri"

class DeleteCollectionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 5

  def perform(product_id)
    collection_name = "product_#{product_id}"

    qdrant_url = ENV.fetch("QDRANT_URL")
    api_key    = ENV["QDRANT_API_KEY"]

    uri = URI.parse("#{qdrant_url}/collections/#{collection_name}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Delete.new(uri.request_uri)

    request["api-key"] = api_key if api_key.present?

    response = http.request(request)

    unless response.code.to_i == 200
      raise "Qdrant deletion failed: #{response.body}"
    end

    Rails.logger.info "✅ Deleted Qdrant collection #{collection_name}"
  end
end
