class OrdersController < ApplicationController
  def index
    @orders = Order.includes(:customer, products: :category).order(created_at: :desc)
  end

  def new
    @order = Order.new
    load_form_options
  end

  def create
    @order = Order.new(order_params)

    if @order.save
      redirect_to orders_path, notice: "Order was created successfully."
    else
      load_form_options
      render :new, status: :unprocessable_entity
    end
  end

  private

  def order_params
    params.require(:order).permit(:customer_id, product_ids: [])
  end

  def load_form_options
    @customers = Customer.order(:name)
    @products = Product.includes(:category).order(:name)
  end
end
