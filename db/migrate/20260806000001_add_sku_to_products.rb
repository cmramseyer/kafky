class AddSkuToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :sku, :string, null: false
    add_index :products, :sku, unique: true
  end
end
