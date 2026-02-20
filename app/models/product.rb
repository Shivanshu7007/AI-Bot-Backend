class Product < ApplicationRecord
  has_many_attached :documents
   has_one_attached :image

  after_commit :enqueue_ingestion, on: [:create]
  after_destroy_commit :enqueue_collection_deletion

  private

  # ---------------------------
  # INGEST DOCUMENTS
  # ---------------------------
  def enqueue_ingestion
    return unless documents.attached?

    documents.each do |doc|
      IngestDocumentJob.perform_later(self.id, doc.blob.id)
    end
  end

  # ---------------------------
  # SAFE DELETE VIA JOB
  # ---------------------------
  def enqueue_collection_deletion
    DeleteCollectionJob.perform_later(self.id)
  end

  # ---------------------------
  # RANSACK SAFE
  # ---------------------------
# ---------------------------
# RANSACK SAFE
# ---------------------------
  def self.ransackable_attributes(_auth_object = nil)
    %w[id name description created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    []
  end
end
