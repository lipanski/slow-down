require "singleton"
require "logger"
require "redis"
require "slow_down/strategy/linear"
require "slow_down/strategy/fibonacci"
require "slow_down/strategy/inverse_exponential"

module SlowDown
  class Configuration
    include Singleton

    CONCURRENCY_MULTIPLIER = 1

    DEFAULTS = {
      requests_per_second: 10,
      timeout: 5,
      retries: 30,
      retry_strategy: :linear,
      registered_retry_strategies: [Strategy::Linear, Strategy::Fibonacci, Strategy::InverseExponential],
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

    private

    def initialize
      @user = {}
    end

    def seconds_per_retry_arr
      @seconds_per_retry_arr ||= begin
        klass = retry_strategy.is_a?(Class) ? retry_strategy : retry_strategy_mapping.fetch(retry_strategy)
        klass.new(retries, timeout).normalized_series
      end
    end

    def retry_strategy_mapping
      @retry_strategy_mapping ||= begin
        registered_retry_strategies.each_with_object({}) do |el, acc|
          el.aliases.each { |name| acc[name] = el }
        end
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
      @retry_strategy_mapping = nil
    end
  end
end
