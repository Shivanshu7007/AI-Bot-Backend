require "net/http"
require "uri"

class DeleteCollectionJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(product_id)
    python_url = ENV.fetch("PYTHON_API_URL")
    api_key    = ENV.fetch("SERVICE_API_KEY")

    uri = URI.parse("#{python_url}/collection/#{product_id}")

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl      = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 15

    request = Net::HTTP::Delete.new(uri.request_uri, {
      "x-api-key" => api_key
    })

    response = http.request(request)
    code     = response.code.to_i

    if code == 200
      Rails.logger.info "[DeleteCollectionJob] Successfully deleted Qdrant collection for product #{product_id}"
    else
      Rails.logger.error "[DeleteCollectionJob] Python service returned #{code} for product #{product_id}: #{response.body}"
      raise "Collection deletion failed with status #{code}"
    end

  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "[DeleteCollectionJob] Timeout deleting collection for product #{product_id}: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "[DeleteCollectionJob] Error deleting collection for product #{product_id}: #{e.message}"
    raise
  end
end
