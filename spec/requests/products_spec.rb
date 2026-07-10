require "rails_helper"

RSpec.describe "Products API", type: :request do
  let(:category) { Category.create!(name: "Test Category") }
  let!(:product) { Product.create!(name: "Existing Product", description: "desc", price: 10, stock: 5, category: category) }

  let(:user) { User.create!(email: "spec@example.com", password: "password123") }
  let(:auth_headers) do
    token = JsonWebToken.encode(user_id: user.id)
    { "Authorization" => "Bearer #{token}" }
  end

  describe "GET /products" do
    it "returns all products without requiring auth" do
      get "/products"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(1)
    end
  end

  describe "GET /products/:id" do
    it "returns a single product" do
      get "/products/#{product.id}"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["name"]).to eq("Existing Product")
    end

    it "returns 404 for a missing product" do
      get "/products/999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /products" do
    let(:valid_params) { { product: { name: "New Product", description: "desc", price: 20, stock: 3, category_id: category.id } } }

    it "rejects the request without auth" do
      post "/products", params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    it "creates a product with valid auth" do
      post "/products", params: valid_params, headers: auth_headers
      expect(response).to have_http_status(:created)
      expect(Product.count).to eq(2)
    end

    it "returns errors for invalid params" do
      post "/products", params: { product: { name: "" } }, headers: auth_headers
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "DELETE /products/:id" do
    it "deletes the product with valid auth" do
      delete "/products/#{product.id}", headers: auth_headers
      expect(response).to have_http_status(:no_content)
      expect(Product.exists?(product.id)).to be false
    end

    it "rejects deletion without auth" do
      delete "/products/#{product.id}"
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
