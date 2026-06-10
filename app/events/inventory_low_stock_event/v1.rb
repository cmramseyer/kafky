module InventoryLowStockEvent
  class V1
    attr_reader :event_id, :event_type, :event_version, :source, :occurred_at, :data

    def initialize(event_id:, event_type:, event_version:, source:, occurred_at:, data:)
      @event_id = event_id
      @event_type = event_type
      @event_version = event_version
      @source = source
      @occurred_at = occurred_at
      @data = data
    end

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

    def product
      data.product
    end

    class Data
      attr_reader :product

      def initialize(product:)
        @product = product
      end
    end

    class Product
      attr_reader :id, :name, :stock, :reorder_threshold

      def initialize(id:, name:, stock:, reorder_threshold:)
        @id = id
        @name = name
        @stock = stock
        @reorder_threshold = reorder_threshold
      end
    end
  end
end
