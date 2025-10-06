class AdminUser < ApplicationRecord
  # Include default devise modules.
  devise :database_authenticatable, :recoverable, :rememberable, :validatable

  # Allowlist searchable attributes for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    ["id", "email", "created_at", "updated_at"]
  end

  # If you have associations you want searchable, allowlist them
  def self.ransackable_associations(auth_object = nil)
    []
  end
end
