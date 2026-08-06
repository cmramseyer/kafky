module OrderCreatedEvent
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

    def order
      data.order
    end

    class Data
      attr_reader :order

      def initialize(order:)
        @order = order
      end
    end

    class Order
      attr_reader :id, :customer_id, :products

      def initialize(id:, customer_id:, products:)
        @id = id
        @customer_id = customer_id
        @products = products
      end
    end

    class Product
      attr_reader :sku, :quantity

      def initialize(sku:, quantity:)
        @sku = sku
        @quantity = quantity
      end
    end
  end
end
