class ProductsController < ApplicationController
  before_action :set_product, only: [ :show, :update, :destroy ]
  before_action :authenticate_request, only: [ :create, :update, :destroy ]

  def index
    @products = Product.includes(:category)
    render json: @products.as_json(include: { category: { only: :name } })
  end

  def show
    render json: @product.as_json(include: { category: { only: :name } })
  end

  def create
    @product = Product.new(product_params)

    if @product.save
      ProductNotifierJob.perform_later(@product.id)
      render json: @product, status: :created
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_content
    end
  end

  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: { errors: @product.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    @product.destroy
    head :no_content
  end

  private

  def set_product
    @product = Product.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Product not found" }, status: :not_found
  end

  def product_params
    params.require(:product).permit(:name, :description, :price, :stock, :category_id)
  end
end
