module InventoryLowStockEvent
  class V1
    def self.payload(event_id:, product:, occurred_at: Time.current)
      {
        event_id: event_id,
        event_type: "inventory.low_stock",
        event_version: 1,
        source: "kafky",
        occurred_at: occurred_at.iso8601,
        data: {
          product: {
            id: product.id,
            name: product.name,
            stock: product.stock,
            reorder_threshold: product.reorder_threshold
          }
        }
      }
    end
  end
end
