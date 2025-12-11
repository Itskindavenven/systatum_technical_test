require "spec"
require "json"
require "../src/models/product"

describe Product do
  it "correctly merges arbitrary fields" do
    Product.clear
    
    initial_data = {"name" => JSON::Any.new("Ultramie"), "price" => JSON::Any.new(25000_i64)}
    created = Product.create(initial_data)
    created[:fields]["name"].as_s.should eq("Ultramie")

    update_data = {"price" => JSON::Any.new(30000_i64)}
    updated = Product.update(created[:id], update_data)
    
    result = updated.not_nil!
    result[:fields]["price"].as_i.should eq(30000)
    result[:fields]["name"].as_s.should eq("Ultramie") 
  end

  it "supports pagination" do
    Product.clear
    
    5.times do |i|
      Product.create({"name" => JSON::Any.new("Product #{i + 1}"), "price" => JSON::Any.new((i + 1) * 1000_i64)})
    end
    
    Product.count.should eq(5)
    
    page1 = Product.paginate(1, 2)
    page1.size.should eq(2)
    
    page2 = Product.paginate(2, 2)
    page2.size.should eq(2)
    
    page3 = Product.paginate(3, 2)
    page3.size.should eq(1)
    
    all = Product.all
    all.size.should eq(5)
  end
end