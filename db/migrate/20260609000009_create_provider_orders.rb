class CreateProviderOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :provider_orders do |t|
      t.references :product, null: false, foreign_key: true
      t.integer :quantity, null: false

      t.timestamps
    end
  end
end
