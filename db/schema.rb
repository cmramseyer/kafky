# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_06_09_000009) do
  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "order_products", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "order_id", null: false
    t.integer "product_id", null: false
    t.integer "quantity", default: 1, null: false
    t.datetime "updated_at", null: false
    t.index ["order_id", "product_id"], name: "index_order_products_on_order_id_and_product_id", unique: true
    t.index ["order_id"], name: "index_order_products_on_order_id"
    t.index ["product_id"], name: "index_order_products_on_product_id"
  end

  create_table "orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "customer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_orders_on_customer_id"
  end

  create_table "outbox_events", force: :cascade do |t|
    t.bigint "aggregate_id", null: false
    t.string "aggregate_type", null: false
    t.datetime "created_at", null: false
    t.string "event_id", null: false
    t.string "event_type", null: false
    t.json "payload", null: false
    t.datetime "published_at"
    t.datetime "updated_at", null: false
    t.index ["aggregate_type", "aggregate_id"], name: "index_outbox_events_on_aggregate_type_and_aggregate_id"
    t.index ["event_id"], name: "index_outbox_events_on_event_id", unique: true
    t.index ["published_at"], name: "index_outbox_events_on_published_at"
  end

  create_table "products", force: :cascade do |t|
    t.integer "category_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "reorder_threshold", default: 0, null: false
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_products_on_category_id"
  end

  create_table "provider_orders", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "product_id", null: false
    t.integer "quantity", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_provider_orders_on_product_id"
  end

  add_foreign_key "order_products", "orders"
  add_foreign_key "order_products", "products"
  add_foreign_key "orders", "customers"
  add_foreign_key "products", "categories"
  add_foreign_key "provider_orders", "products"
end
