require "test_helper"

class CatalogEventsConsumerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "updates the local price and broadcasts the order form price" do
    product = create_product

    streams = capture_turbo_stream_broadcasts("new_order_products") do
      process_message(
        CatalogEventsConsumer,
        event_type: "product.price_updated",
        source: "kafky_prices",
        data: { sku: product.sku, prd_price: "24.50" }
      )
    end

    assert_equal 24.5, product.reload.price.to_f
    assert_equal "replace", streams.first["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(product, :order_form_price), streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "$24.50"
    assert_includes streams.first.at("template").inner_html, "price-update-highlight"
  end

  private

  def create_product
    category = Category.create!(name: "Hardware")
    Product.create!(
      category: category,
      name: "Keyboard",
      sku: "KEYBOARD-1",
      price: 19.99,
      stock: 10,
      reorder_threshold: 2
    )
  end

  def process_message(consumer_class, event_type:, source:, data:)
    payload = {
      event_type: event_type,
      event_version: 1,
      source: source,
      data: data
    }
    message = Struct.new(:payload).new(payload.to_json)

    consumer_class.new.send(:process_message, message)
  end
end
