require "test_helper"

class NewOrderRealtimeTest < ActionDispatch::IntegrationTest
  test "renders the order form stream and live product targets" do
    category = Category.create!(name: "Hardware")
    product = Product.create!(
      category: category,
      name: "Keyboard",
      sku: "KEYBOARD-1",
      price: 19.99,
      stock: 10,
      reorder_threshold: 2
    )

    get new_order_path

    assert_response :success
    assert_select "turbo-cable-stream-source[signed-stream-name]", count: 1
    assert_select "td##{ActionView::RecordIdentifier.dom_id(product, :order_form_price)}", text: "$19.99"
    assert_select "td##{ActionView::RecordIdentifier.dom_id(product, :order_form_stock)}", text: "10"
  end
end
