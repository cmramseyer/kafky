require "json"

class InventoryStockEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_message(message)
    end
  end

  private

  def process_message(message)
    payload = message.payload.is_a?(String) ? JSON.parse(message.payload) : message.payload
    validate_event!(payload)
    data = payload.fetch("data")
    product = Product.find_by!(sku: data.fetch("sku"))

    product.update!(stock: data.fetch("available_quantity"))
    broadcast_product_stock(product)
  end

  def broadcast_product_stock(product)
    Turbo::StreamsChannel.broadcast_replace_to(
      "new_order_products",
      target: ActionView::RecordIdentifier.dom_id(product, :order_form_stock),
      partial: "orders/product_stock_update",
      locals: { product: product }
    )
  end

  def validate_event!(payload)
    return if payload.fetch("event_type") == "inventory.stock_updated" &&
              payload.fetch("source") == "kafky_storage" &&
              payload.fetch("event_version").to_i == 1

    raise ArgumentError,
          "Unsupported inventory.stock_updated source=#{payload.fetch("source").inspect} event_version=#{payload.fetch("event_version").inspect}"
  end
end
