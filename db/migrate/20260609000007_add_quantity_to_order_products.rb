class AddQuantityToOrderProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :order_products, :quantity, :integer, null: false, default: 1
  end
end
