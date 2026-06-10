class ProviderOrdersController < ApplicationController
  def index
    @provider_orders = ProviderOrder.includes(:product).order(created_at: :desc)
  end
end
