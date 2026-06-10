class ProviderOrder < ApplicationRecord
  belongs_to :product

  validates :product_id, presence: true
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }
end
