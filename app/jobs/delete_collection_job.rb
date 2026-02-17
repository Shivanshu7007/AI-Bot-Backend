require "net/http"
require "uri"

class DeleteCollectionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 5

  def perform(product_id)
    collection_name = "product_#{product_id}"
    qdrant_url = ENV.fetch("QDRANT_URL", "http://localhost:6333")

    uri = URI.parse("#{qdrant_url}/collections/#{collection_name}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Delete.new(uri.request_uri)

    response = http.request(request)

    if response.code.to_i == 200
      Rails.logger.info "✅ Deleted Qdrant collection #{collection_name}"
    else
      raise "Qdrant deletion failed: #{response.body}"
    end
  end
end
