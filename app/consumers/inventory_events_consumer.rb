class InventoryEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      process_message(message)
    end
  end

  private

  def process_message(message)
    event = InventoryLowStockEvent::Adapter.call(message.payload)

    Rails.logger.info(
      "Kafka inventory.events message received: key=#{message.key.inspect} event_id=#{event.event_id} " \
      "source=#{event.source} event_version=#{event.event_version}"
    )

    ProviderOrderRequestHandler.call(event)
  rescue StandardError => error
    Rails.logger.error(
      "Kafka inventory.events message skipped: key=#{message.key.inspect} error=#{error.class}: #{error.message}"
    )
  end
end
