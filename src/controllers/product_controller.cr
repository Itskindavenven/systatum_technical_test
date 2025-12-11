require "../models/product"

module ProductController
  extend self

  def health(env)
    {status: "ok", timestamp: Time.utc.to_s}.to_json
  end

  def index(env)
    page = env.params.query["page"]?.try(&.to_i) || 1
    per_page = env.params.query["per_page"]?.try(&.to_i) || 20
    
    page = 1 if page < 1
    per_page = 100 if per_page > 100
    per_page = 1 if per_page < 1
    
    products = Product.paginate(page, per_page)
    total = Product.count
    
    {
      data: products,
      pagination: {
        page: page,
        per_page: per_page,
        total: total,
        total_pages: (total.to_f / per_page).ceil.to_i
      }
    }.to_json
  end

  def create(env)
    begin
      json_fields = env.params.json["fields"]?
      return halt(env, status_code: 400, response: {error: "Invalid Payload. Expected {fields: {...}}"}.to_json) unless json_fields
      
      fields = json_fields.as_h
      product = Product.create(fields)
      product.to_json
    rescue
      halt env, status_code: 400, response: {error: "Invalid Payload. Expected {fields: {...}}"}.to_json
    end
  end

  def show(env)
    id = env.params.url["id"].to_i?
    product = Product.find(id)
    
    if product
      product.to_json
    else
      halt env, status_code: 404, response: {error: "Product not found"}.to_json
    end
  end

  def update(env)
    id = env.params.url["id"].to_i?
    begin
      json_fields = env.params.json["fields"]?
      return halt(env, status_code: 400, response: {error: "Invalid Payload"}.to_json) unless json_fields
      
      new_fields = json_fields.as_h
      product = Product.update(id, new_fields)
      
      if product
        product.to_json
      else
        halt env, status_code: 404, response: {error: "Product not found"}.to_json
      end
    rescue
      halt env, status_code: 400, response: {error: "Invalid Payload"}.to_json
    end
  end

  def delete(env)
    id = env.params.url["id"].to_i?
    Product.delete(id)
    {message: "Product deleted"}.to_json
  end
end