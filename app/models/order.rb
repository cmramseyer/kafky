class Order < ApplicationRecord
  belongs_to :customer
  has_many :order_products, dependent: :destroy
  has_many :products, through: :order_products

  validate :at_least_one_order_product

  private

  def at_least_one_order_product
    errors.add(:base, "Select at least one product") if order_products.empty?
  end
end
