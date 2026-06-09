namespace :outbox do
  desc "Publish pending outbox events to Kafka"
  task publish: :environment do
    published_count = OutboxEventPublisher.call

    puts "Published #{published_count} outbox event(s) to Kafka."
  end
end
