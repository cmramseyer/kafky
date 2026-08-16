require "json"

class CatalogEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_message(message)
    end
  end

  private

  def process_message(message)
    payload = message.payload.is_a?(String) ? JSON.parse(message.payload) : message.payload

    case payload.fetch("event_type")
    when "product.created"
      create_or_update_product(payload)
    when "product.price_updated"
      update_product_price(payload)
    end
  end

  def create_or_update_product(payload)
    validate_event!(payload, "product.created")
    data = payload.fetch("data")
    category = Category.find_or_create_by!(name: data.fetch("prd_category"))
    product = Product.find_or_initialize_by(sku: data.fetch("sku"))

    product.assign_attributes(
      name: data.fetch("product_desc"),
      price: data.fetch("prd_price"),
      category: category
    )
    product.save!
  end

  def update_product_price(payload)
    validate_event!(payload, "product.price_updated")
    data = payload.fetch("data")
    product = Product.find_by!(sku: data.fetch("sku"))

    product.update!(price: data.fetch("prd_price"))
    broadcast_product_price(product)
  end

  def broadcast_product_price(product)
    Turbo::StreamsChannel.broadcast_replace_to(
      "new_order_products",
      target: ActionView::RecordIdentifier.dom_id(product, :order_form_price),
      partial: "orders/product_price_update",
      locals: { product: product }
    )
  end

  def validate_event!(payload, event_type)
    return if payload.fetch("event_type") == event_type &&
              payload.fetch("source") == "kafky_prices" &&
              payload.fetch("event_version").to_i == 1

    raise ArgumentError,
          "Unsupported #{event_type} source=#{payload.fetch("source").inspect} event_version=#{payload.fetch("event_version").inspect}"
  end
end
