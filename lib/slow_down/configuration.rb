require "logger"
require "redis"
require "slow_down/strategy/linear"
require "slow_down/strategy/fibonacci"
require "slow_down/strategy/inverse_exponential"

module SlowDown
  class Configuration
    CONCURRENCY_MULTIPLIER = 1

    DEFAULTS = {
      requests_per_second: 10,
      timeout: 5,
      retries: 30,
      retry_strategy: :default,
      raise_on_timeout: false,
      redis: nil,
      redis_url: nil,
      redis_namespace: :slow_down,
      concurrency: nil,
      log_path: STDOUT,
      log_level: Logger::INFO
    }

    DEFAULTS.each do |key, default_value|
      define_method(key) do
        @user[key] || default_value
      end

      define_method("#{key}=") do |value|
        @user[key] = value
        invalidate
      end
    end

    def initialize(options)
      @user = {}
      @options = DEFAULTS.merge(options)
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
      @concurrency ||= @user[:concurrency] || [1, requests_per_second.ceil * CONCURRENCY_MULTIPLIER].max
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

    def seconds_per_retry(retry_count)
      seconds_per_retry_arr[retry_count - 1]
    end

    def seconds_per_retry_arr
      @seconds_per_retry_arr ||= begin
        klass =
          case retry_strategy
          when :linear, :default
            Strategy::Linear
          when :fibonacci
            Strategy::Fibonacci
          when :inverse_exponential
            Strategy::InverseExponential
          else
            retry_strategy
          end

        unless klass < Strategy::Base
          fail ":retry_strategy should be a class inheriting SlowDown::Strategy::Base"
        end

        klass.new(retries, timeout).normalized_series
      end
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
      @seconds_per_retry_arr = nil
    end
  end
end
