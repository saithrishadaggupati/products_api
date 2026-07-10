electronics = Category.create!(name: "Electronics")
books = Category.create!(name: "Books")
toys = Category.create!(name: "Toys")

10.times do |i|
  Product.create!(
    name: "Product #{i}",
    description: "Description for product #{i}",
    price: (10 + i).to_f,
    stock: 50,
    category: [electronics, books, toys].sample
  )
end
