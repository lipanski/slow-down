require "singleton"
require "logger"
require "redis"

module SlowDown
  class Configuration
    include Singleton

    DEFAULTS = {
      requests_per_second: 2,
      timeout: 5,
      retries: 10,
      retry_strategy: :liniar,
      raise_on_timeout: false,
      redis: nil,
      redis_url: nil,
      redis_namespace: :slow_down,
      concurrency: nil,
      log_path: STDOUT,
      log_level: Logger::INFO
    }

    DEFAULTS.each do |key, default_value|
      # Getters
      define_method(key) do
        @user[key] || default_value
      end

      # Setters
      define_method("#{key}=") do |value|
        @user[key] = value
        invalidate
      end
    end

    def logger
      @logger ||= Logger.new(log_path).tap do |l|
        l.level = log_level
      end
    end

    def redis
      @redis ||= @user[:redis] || Redis.new(url: redis_url || ENV.fetch("REDIS_URL"))
    end

    def concurrency
      @concurrency ||= [1, requests_per_second.ceil].max
    end

    def locks
      @locks ||= concurrency.times.map do |i|
        [redis_namespace, "lock_#{i}"].compact.join(":")
      end
    end

    def miliseconds_per_request
      @miliseconds_per_request ||= 1000.0 / requests_per_second
    end

    def miliseconds_per_request_per_lock
      @miliseconds_per_request_per_lock ||= (miliseconds_per_request * concurrency).round
    end

    def seconds_per_retry
      @seconds_per_retry ||= timeout.to_f / retries
    end

    private

    def initialize
      @user = {}
    end

    def invalidate
      @redis = nil
      @log_path = nil
      @log_level = nil
      @concurrency = nil
      @locks = nil
      @miliseconds_per_request = nil
      @miliseconds_per_request_per_lock = nil
      @seconds_per_retry = nil
    end
  end
end
