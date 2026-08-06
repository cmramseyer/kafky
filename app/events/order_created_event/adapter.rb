require "json"

module OrderCreatedEvent
  class Adapter
    ADAPTERS = {
      [ "kafky", 1 ] => :from_v1_payload,
      [ "manual", 1 ] => :from_v1_payload
    }.freeze

    def self.call(...)
      new(...).call
    end

    def initialize(payload)
      @payload = normalize_payload(payload)
    end

    def call
      adapter = ADAPTERS.fetch([ source, event_version ]) do
        raise ArgumentError, "Unsupported order.created source=#{source.inspect} event_version=#{event_version.inspect}"
      end

      send(adapter)
    end

    private

    attr_reader :payload

    def from_v1_payload
      validate_event_type!

      order_payload = payload.fetch("data").fetch("order")

      V1.new(
        event_id: payload.fetch("event_id"),
        event_type: payload.fetch("event_type"),
        event_version: event_version,
        source: source,
        occurred_at: payload.fetch("occurred_at"),
        data: V1::Data.new(
          order: V1::Order.new(
            id: order_payload.fetch("id").to_i,
            customer_id: order_payload.fetch("customer_id").to_i,
            products: build_products(order_payload.fetch("products"))
          )
        )
      )
    end

    def build_products(products_payload)
      products_payload.map do |product_payload|
        V1::Product.new(
          sku: product_payload.fetch("sku"),
          quantity: product_quantity(product_payload)
        )
      end
    end

    def product_quantity(product_payload)
      quantity = product_payload["quantity"] || product_payload["qty"]
      raise KeyError, "Missing product quantity" if quantity.blank?

      quantity.to_i
    end

    def validate_event_type!
      return if payload.fetch("event_type") == "order.created"

      raise ArgumentError, "Unsupported event_type=#{payload.fetch("event_type").inspect}"
    end

    def source
      payload.fetch("source")
    end

    def event_version
      payload.fetch("event_version").to_i
    end

    def normalize_payload(raw_payload)
      parsed_payload = raw_payload.is_a?(String) ? JSON.parse(raw_payload) : raw_payload
      deep_stringify_keys(parsed_payload)
    end

    def deep_stringify_keys(value)
      case value
      when Hash
        value.each_with_object({}) do |(key, child_value), result|
          result[key.to_s] = deep_stringify_keys(child_value)
        end
      when Array
        value.map { |child_value| deep_stringify_keys(child_value) }
      else
        value
      end
    end
  end
end
