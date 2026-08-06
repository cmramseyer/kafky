class OutboxEventPublisher
  TOPICS_BY_EVENT_TYPE = {
    "order.created" => "orders.events"
  }.freeze

  def self.call(...)
    new(...).call
  end

  def initialize(limit: 100)
    @limit = limit
  end

  def call
    published_count = 0

    OutboxEvent.pending.order(:created_at).limit(limit).each do |event|
      publish(event)
      event.update!(published_at: Time.current)
      published_count += 1
    end

    published_count
  end

  private

  attr_reader :limit

  def publish(event)
    payload = event.payload

    Karafka.producer.produce_sync(
      topic: topic_for(event),
      key: event.aggregate_id.to_s,
      payload: payload.to_json,
      headers: {
        "event_id" => event.event_id,
        "event_type" => event.event_type,
        "event_version" => payload["event_version"].to_s,
        "source" => payload["source"].to_s
      }
    )
  end

  def topic_for(event)
    TOPICS_BY_EVENT_TYPE.fetch(event.event_type)
  end
end
