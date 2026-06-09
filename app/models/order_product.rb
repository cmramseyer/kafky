class OrderProduct < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :product_id, uniqueness: { scope: :order_id }
end
