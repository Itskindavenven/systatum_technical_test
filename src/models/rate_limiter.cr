require "json"

class RateLimiter
  @@requests = Hash(String, Array(Time)).new
  @@mutex = Mutex.new

  def self.check(ip : String, limit = 100, window = 60)
    @@mutex.synchronize do
      now = Time.utc
      @@requests[ip] ||= [] of Time
      
      # Remove requests outside the time window
      @@requests[ip].reject! { |t| (now - t).total_seconds > window }
      
      # Check if limit exceeded
      if @@requests[ip].size >= limit
        return false
      end
      
      # Record this request
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
