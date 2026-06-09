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
  [ "Wireless Mouse", 24.99, "Electronics" ],
  [ "Mechanical Keyboard", 89.99, "Electronics" ],
  [ "USB-C Hub", 39.99, "Electronics" ],
  [ "Ruby Programming Book", 34.50, "Books" ],
  [ "Rails Patterns Book", 42.00, "Books" ],
  [ "Desk Lamp", 27.75, "Home" ],
  [ "Coffee Mug", 12.25, "Home" ],
  [ "Yoga Mat", 22.00, "Sports" ],
  [ "Running Bottle", 15.99, "Sports" ],
  [ "Resistance Bands", 18.50, "Sports" ]
]

products.each do |name, price, category_name|
  Product.find_or_create_by!(name: name) do |product|
    product.price = price
    product.category = categories.fetch(category_name)
  end
end
