class OrdersEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      Rails.logger.info(
        "Kafka orders.events message received: key=#{message.key.inspect} payload=#{message.payload}"
      )
    end
  end
end
