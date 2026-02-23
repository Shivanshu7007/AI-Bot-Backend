class Product < ApplicationRecord
  has_one_attached :image, service: :cloudinary
  has_many_attached :documents, service: :local

  after_commit :enqueue_ingestion, on: [:create]
  after_destroy_commit :enqueue_collection_deletion
  validate :validate_document_types

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

  def validate_document_types
    documents.each do |doc|
      unless doc.filename.to_s.downcase.match?(/\.(pdf|docx|txt|yaml|yml|json)\z/)
        errors.add(:documents, "Only PDF, DOCX, TXT, YAML, JSON files are allowed.")
      end
    end
  end
end