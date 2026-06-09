class AddInventoryFieldsToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :stock, :integer, null: false, default: 0
    add_column :products, :reorder_threshold, :integer, null: false, default: 0
  end
end
