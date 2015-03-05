require "singleton"

module SlowDown
  class Configuration
    include Singleton

    DEFAULTS = {
      requests_per_second: 10,
      timeout: 5,
      retries: 100,
      retry_strategy: :liniar,
      raise_on_timeout: false
    }

    DEFAULTS.each do |key, default_value|
      # Getters
      define_method(key) do
        instance_variable_get("@#{key}") || default_value
      end

      # Setters
      define_method("#{key}=") do |value|
        @invalidate = true
        instance_variable_set("@#{key}", value || default_value)
      end
    end

    def miliseconds_per_request
      @miliseconds_per_request ||= (1000 / requests_per_second).round
    end

    def seconds_per_retry
      @seconds_per_retry ||= timeout.to_f / retries
    end
  end
end
