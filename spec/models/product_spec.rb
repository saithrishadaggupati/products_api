require "rails_helper"

RSpec.describe Product, type: :model do
  it { should belong_to(:category) }
  it { should validate_presence_of(:name) }

  it "is valid with valid attributes" do
    category = Category.create!(name: "Test Category")
    product = Product.new(name: "Test Product", description: "desc", price: 9.99, stock: 5, category: category)
    expect(product).to be_valid
  end
end
