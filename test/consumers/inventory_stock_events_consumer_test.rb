require "test_helper"

class InventoryStockEventsConsumerTest < ActiveSupport::TestCase
  include Turbo::Broadcastable::TestHelper

  test "updates the local stock and broadcasts the order form stock" do
    product = create_product

    streams = capture_turbo_stream_broadcasts("new_order_products") do
      process_message(product)
    end

    assert_equal 4, product.reload.stock
    assert_equal "replace", streams.first["action"]
    assert_equal ActionView::RecordIdentifier.dom_id(product, :order_form_stock), streams.first["target"]
    assert_includes streams.first.at("template").inner_html, "4"
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

  def process_message(product)
    payload = {
      event_type: "inventory.stock_updated",
      event_version: 1,
      source: "kafky_storage",
      data: { sku: product.sku, available_quantity: 4 }
    }
    message = Struct.new(:payload).new(payload.to_json)

    InventoryStockEventsConsumer.new.send(:process_message, message)
  end
end
