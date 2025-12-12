require "kemal"
require "./controllers/product_controller"

require "./models/rate_limiter"

before_all do |env|
  env.response.content_type = "application/json"
  
  unless RateLimiter.check(env.request.remote_address.to_s)
    env.response.status_code = 429
    halt env, response: {error: "Rate limit exceeded"}.to_json
  end
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


error 404 do |env|
  env.response.content_type = "application/json"
  {error: "Not Found"}.to_json
end

error 500 do |env, exception|
  env.response.content_type = "application/json"
  {error: exception.message}.to_json
end

Kemal.run