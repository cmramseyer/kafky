require "karafka"
require_dependency Rails.root.join("app/consumers/application_consumer").to_s
require_dependency Rails.root.join("app/consumers/catalog_events_consumer").to_s
require_dependency Rails.root.join("app/consumers/inventory_stock_events_consumer").to_s
require_dependency Rails.root.join("app/consumers/orders_events_consumer").to_s
require_dependency Rails.root.join("app/consumers/inventory_events_consumer").to_s

class KarafkaApp < Karafka::App
  setup do |config|
    config.client_id = "kafky"
    config.kafka = {
      "bootstrap.servers": ENV.fetch("KAFKA_BOOTSTRAP_SERVERS", "localhost:9092")
    }
    config.consumer_persistence = !Rails.env.development?
  end

  routes.draw do
    topic "catalog.events" do
      consumer CatalogEventsConsumer
    end

    topic "inventory.stock.events" do
      consumer InventoryStockEventsConsumer
    end

    topic "orders.events" do
      consumer OrdersEventsConsumer
    end

    topic "inventory.events" do
      consumer InventoryEventsConsumer
    end
  end
end
