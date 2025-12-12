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
      
      unless json_fields
        env.response.status_code = 400
        return {error: "Invalid Payload. Expected {fields: {...}}"}.to_json
      end

      fields = json_fields.as(Hash(String, JSON::Any))
      product = Product.create(fields)
      product.to_json
    rescue ex
      puts "Create Error: #{ex.message}"
      env.response.status_code = 400
      {error: "Invalid Payload or Data Format"}.to_json
    end
  end

  def show(env)
    begin
      id_str = env.params.url["id"]
      id = id_str.to_i
    rescue
      env.response.status_code = 400
      return {error: "Invalid Product ID"}.to_json
    end
    
    product = Product.find(id)
    
    if product
      product.to_json
    else
      env.response.status_code = 404
      {error: "Product not found"}.to_json
    end
  end

  def update(env)
    begin
      id_str = env.params.url["id"]
      id = id_str.to_i
    rescue
      env.response.status_code = 400
      return {error: "Invalid Product ID"}.to_json
    end

    begin
      json_fields = env.params.json["fields"]?
      unless json_fields
        env.response.status_code = 400
        return {error: "Invalid Payload. Expected 'fields'"}.to_json
      end
      
      new_fields = json_fields.as(Hash(String, JSON::Any))
      product = Product.update(id, new_fields)
      
      if product
        product.to_json
      else
        env.response.status_code = 404
        {error: "Product not found"}.to_json
      end
    rescue ex
      puts "Update Error: #{ex.message}"
      env.response.status_code = 400
      {error: "Invalid Payload or Data Format"}.to_json
    end
  end

  def delete(env)
    begin
      id_str = env.params.url["id"]
      id = id_str.to_i
    rescue
      env.response.status_code = 400
      return {error: "Invalid Product ID"}.to_json
    end

    Product.delete(id)
    {message: "Product deleted"}.to_json
  end
end