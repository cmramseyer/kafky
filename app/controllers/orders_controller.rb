require "securerandom"

class OrdersController < ApplicationController
  def index
    @orders = Order.includes(:customer, order_products: { product: :category }).order(created_at: :desc)
  end

  def new
    @order = Order.new
    @product_quantities = {}
    load_form_options
  end

  def create
    @product_quantities = product_quantities_params
    @order = Order.new(customer_id: order_params[:customer_id])
    build_order_products

    if save_order_with_outbox_event
      redirect_to orders_path, notice: "Order was created successfully."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_id)
  end

  def product_quantities_params
    raw_quantities = params.require(:order).fetch(:product_quantities, {})
    return raw_quantities.permit!.to_h if raw_quantities.respond_to?(:permit!)

    raw_quantities.to_h
  end

  def build_order_products
    @product_quantities.each do |product_id, quantity|
      next unless quantity.to_i.positive?

      @order.order_products.build(product_id: product_id, quantity: quantity.to_i)
    end
  end

  def save_order_with_outbox_event
    saved = false

    ActiveRecord::Base.transaction do
      saved = @order.save
      create_order_created_event if saved
    end

    saved
  end

  def create_order_created_event
    event_id = SecureRandom.uuid

    OutboxEvent.create!(
      event_id: event_id,
      event_type: "order.created",
      aggregate_type: "Order",
      aggregate_id: @order.id,
      payload: order_created_payload(event_id)
    )
  end

  def order_created_payload(event_id)
    {
      event_id: event_id,
      event_type: "order.created",
      event_version: 1,
      source: "kafky",
      occurred_at: Time.current.iso8601,
      data: {
        order: {
          id: @order.id,
          customer_id: @order.customer_id,
          products: @order.order_products.map do |order_product|
            {
              id: order_product.product_id,
              quantity: order_product.quantity
            }
          end
        }
      }
    }
  end

  def load_form_options
    @customers = Customer.order(:name)
    @products = Product.includes(:category).order(:name)
  end
end
