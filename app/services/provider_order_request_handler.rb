class ProviderOrderRequestHandler
  def self.call(...)
    new(...).call
  end

  def initialize(event)
    @event = event
  end

  def call
    product = Product.find_by(id: event.product.id)

    unless product
      Rails.logger.warn("ProviderOrder product not found: event_id=#{event.event_id} product_id=#{event.product.id}")
      return
    end

    existing_provider_order = ProviderOrder.find_by(product_id: product.id)

    if existing_provider_order
      Rails.logger.info(
        "ProviderOrder already exists: event_id=#{event.event_id} product_id=#{product.id} " \
        "provider_order_id=#{existing_provider_order.id}"
      )
      return existing_provider_order
    end

    provider_order = ProviderOrder.create!(
      product: product,
      quantity: product.reorder_threshold * 2
    )

    Rails.logger.info(
      "ProviderOrder created: event_id=#{event.event_id} product_id=#{product.id} " \
      "provider_order_id=#{provider_order.id} quantity=#{provider_order.quantity}"
    )

    provider_order
  end

  private

  attr_reader :event
end
