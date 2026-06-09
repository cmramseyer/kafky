class OutboxEvent < ApplicationRecord
  validates :event_id, presence: true, uniqueness: true
  validates :event_type, :aggregate_type, :aggregate_id, :payload, presence: true
end
