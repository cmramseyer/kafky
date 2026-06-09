customers = [
  [ "Ana Torres", "ana.torres@example.com" ],
  [ "Carlos Diaz", "carlos.diaz@example.com" ],
  [ "Lucia Gomez", "lucia.gomez@example.com" ],
  [ "Mateo Ruiz", "mateo.ruiz@example.com" ],
  [ "Sofia Vargas", "sofia.vargas@example.com" ],
  [ "Diego Molina", "diego.molina@example.com" ],
  [ "Valeria Castro", "valeria.castro@example.com" ],
  [ "Javier Moreno", "javier.moreno@example.com" ],
  [ "Camila Rojas", "camila.rojas@example.com" ],
  [ "Andres Silva", "andres.silva@example.com" ]
]

customers.each do |name, email|
  Customer.find_or_create_by!(email: email) do |customer|
    customer.name = name
  end
end

categories = [ "Electronics", "Books", "Home", "Sports" ].index_with do |name|
  Category.find_or_create_by!(name: name)
end

products = [
  [ "Wireless Mouse", 24.99, "Electronics", 35, 8 ],
  [ "Mechanical Keyboard", 89.99, "Electronics", 18, 5 ],
  [ "USB-C Hub", 39.99, "Electronics", 24, 6 ],
  [ "Ruby Programming Book", 34.50, "Books", 40, 10 ],
  [ "Rails Patterns Book", 42.00, "Books", 22, 6 ],
  [ "Desk Lamp", 27.75, "Home", 16, 4 ],
  [ "Coffee Mug", 12.25, "Home", 60, 12 ],
  [ "Yoga Mat", 22.00, "Sports", 28, 7 ],
  [ "Running Bottle", 15.99, "Sports", 45, 10 ],
  [ "Resistance Bands", 18.50, "Sports", 30, 8 ]
]

products.each do |name, price, category_name, stock, reorder_threshold|
  product = Product.find_or_initialize_by(name: name)
  product.price = price
  product.category = categories.fetch(category_name)
  product.stock = stock
  product.reorder_threshold = reorder_threshold
  product.save!
end
