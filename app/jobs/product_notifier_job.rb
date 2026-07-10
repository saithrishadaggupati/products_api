class ProductNotifierJob < ApplicationJob
  queue_as :default

  def perform(product_id)
    product = Product.find(product_id)
    # Simulates sending a notification email.
    # In production this would call ProductMailer.new_product(product).deliver_now
    Rails.logger.info "[ProductNotifierJob] Notification sent for new product: #{product.name} (##{product.id})"
  end
end
