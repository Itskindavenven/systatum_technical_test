require "json"

class RateLimiter
  @@requests = Hash(String, Array(Time)).new
  @@mutex = Mutex.new

  def self.check(ip : String, limit = 100, window = 60)
    @@mutex.synchronize do
      now = Time.utc
      @@requests[ip] ||= [] of Time
      
      @@requests[ip].reject! { |t| (now - t).total_seconds > window }
      
      if @@requests[ip].size >= limit
        return false
      end
      
      @@requests[ip] << now
      true
    end
  end

  def self.clear
    @@mutex.synchronize do
      @@requests.clear
    end
  end
end
