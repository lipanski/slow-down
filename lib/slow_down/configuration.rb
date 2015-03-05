require "singleton"
require "redis"

module SlowDown
  class Configuration
    include Singleton

    DEFAULTS = {
      requests_per_second: 10,
      timeout: 5,
      retries: 100,
      retry_strategy: :liniar,
      raise_on_timeout: false,
      redis: nil,
      redis_url: nil,
      redis_namespace: :slow_down,
      locks_count: nil
    }

    DEFAULTS.each do |key, default_value|
      # Getters
      define_method(key) do
        instance_variable_get("@#{key}") || default_value
      end

      # Setters
      define_method("#{key}=") do |value|
        invalidate
        instance_variable_set("@#{key}", value.nil? ? default_value : value)
      end
    end

    def redis
      @redis ||= Redis.new(url: redis_url || ENV.fetch("REDIS_URL"))
    end

    def locks_count
      @locks_count ||= [1, requests_per_second.ceil].max
    end

    def locks
      @locks ||= locks_count.times.map do |i|
        [redis_namespace, "lock_#{i}"].compact.join(":")
      end
    end

    def miliseconds_per_request
      @miliseconds_per_request ||= 1000.0 / requests_per_second
    end

    def miliseconds_per_request_per_lock
      @miliseconds_per_request_per_lock ||= (miliseconds_per_request * locks_count).round
    end

    def seconds_per_retry
      @seconds_per_retry ||= timeout.to_f / retries
    end

    private

    def invalidate
      @locks_count = nil
      @locks = nil
      @miliseconds_per_request = nil
      @miliseconds_per_request_per_lock = nil
      @seconds_per_retry = nil
    end
  end
end
