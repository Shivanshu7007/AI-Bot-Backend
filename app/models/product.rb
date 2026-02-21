class Product < ApplicationRecord
  has_one_attached :image, service: :cloudinary
  has_many_attached :documents, service: :local

  after_commit :enqueue_ingestion, on: [:create]
  after_destroy_commit :enqueue_collection_deletion

  private

  def enqueue_ingestion
    return unless documents.attached?

    documents.each do |doc|
      IngestDocumentJob.perform_later(self.id, doc.blob.id)
    end
  end

  def enqueue_collection_deletion
    DeleteCollectionJob.perform_later(self.id)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end