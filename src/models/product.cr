require "json"

class Product
  @@storage = Hash(Int32, Hash(String, JSON::Any)).new
  @@last_id = 0
  @@mutex = Mutex.new

  def self.create(fields : Hash(String, JSON::Any))
    @@mutex.synchronize do
      @@last_id += 1
      id = @@last_id
      @@storage[id] = fields
      {id: id, fields: fields}
    end
  end

  def self.find(id : Int32)
    @@storage[id]?
  end

  def self.update(id : Int32, new_fields : Hash(String, JSON::Any))
    @@mutex.synchronize do
      current = @@storage[id]?
      return nil unless current

      updated_fields = current.merge(new_fields)
      
      @@storage[id] = updated_fields
      {id: id, fields: updated_fields}
    end
  end

  def self.delete(id : Int32)
    @@mutex.synchronize do
      @@storage.delete(id)
    end
  end
  
  def self.all
    @@storage.map { |id, fields| {id: id, fields: fields} }
  end

  def self.paginate(page : Int32, per_page : Int32)
    all_products = all()
    start_index = (page - 1) * per_page
    end_index = start_index + per_page - 1
    
    all_products[start_index..end_index]? || [] of Hash(Symbol, Int32 | Hash(String, JSON::Any))
  end

  def self.count
    @@storage.size
  end
  
  def self.clear
    @@mutex.synchronize do
      @@storage.clear
      @@last_id = 0
    end
  end
end