require "securerandom"

class OrderCreatedEventHandler
  def self.call(...)
    new(...).call
  end

  def initialize(event)
    @event = event
  end

  def call
    Product.transaction do
      event.order.products.each do |event_product|
        decrement_stock(event_product)
      end
    end
  end

  private

  attr_reader :event

  def decrement_stock(event_product)
    product = Product.lock.find_by(id: event_product.id)

    unless product
      Rails.logger.warn("OrderCreatedEvent product not found: event_id=#{event.event_id} product_id=#{event_product.id}")
      return
    end

    stock_before = product.stock
    stock_after = [ stock_before - event_product.quantity, 0 ].max

    if event_product.quantity > stock_before
      Rails.logger.warn(
        "OrderCreatedEvent insufficient stock: event_id=#{event.event_id} order_id=#{event.order.id} " \
        "product_id=#{product.id} requested=#{event_product.quantity} stock_before=#{stock_before} stock_after=0"
      )
    end

    product.update!(stock: stock_after)
    create_low_stock_event(product) if product.stock <= product.reorder_threshold

    Rails.logger.info(
      "OrderCreatedEvent stock decremented: event_id=#{event.event_id} order_id=#{event.order.id} " \
      "product_id=#{product.id} quantity=#{event_product.quantity} stock_before=#{stock_before} stock_after=#{stock_after}"
    )
  end

  def create_low_stock_event(product)
    event_id = SecureRandom.uuid

    OutboxEvent.create!(
      event_id: event_id,
      event_type: "inventory.low_stock",
      aggregate_type: "Product",
      aggregate_id: product.id,
      payload: InventoryLowStockEvent::V1.payload(event_id: event_id, product: product)
    )

    Rails.logger.info(
      "InventoryLowStockEvent created: event_id=#{event_id} product_id=#{product.id} " \
      "stock=#{product.stock} reorder_threshold=#{product.reorder_threshold}"
    )
  end
end
