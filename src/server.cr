require "kemal"
require "./controllers/product_controller"

before_all do |env|
  env.response.content_type = "application/json"
end

get "/health" do |env|
  ProductController.health(env)
end

get "/products" do |env|
  ProductController.index(env)
end

post "/products" do |env|
  ProductController.create(env)
end

get "/products/:id" do |env|
  ProductController.show(env)
end

put "/products/:id" do |env|
  ProductController.update(env)
end

delete "/products/:id" do |env|
  ProductController.delete(env)
end

Kemal.run