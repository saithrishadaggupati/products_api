require "rails_helper"

RSpec.describe Category, type: :model do
  it { should have_many(:products) }

  it "is valid with a name" do
    category = Category.new(name: "Electronics")
    expect(category).to be_valid
  end
end
