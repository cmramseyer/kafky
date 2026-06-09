class Customer < ApplicationRecord
  has_many :orders, dependent: :restrict_with_exception

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
