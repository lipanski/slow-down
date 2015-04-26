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
      raise_on_timeout: false,
      retries: 30,
      retry_strategy: :linear,
      redis: nil,
      redis_url: nil,
      redis_namespace: :slow_down,
      lock_namespace: :default,
      concurrency: nil,
      log_path: STDOUT,
      log_level: Logger::UNKNOWN
    }

    DEFAULTS.each do |key, default_value|
      define_method(key) do
        @options[key] || default_value
      end

      define_method("#{key}=") do |value|
        @options[key] = value
        invalidate
      end
    end

    def initialize(options)
      @options = DEFAULTS.merge(options)
    end

    def logger
      @logger ||= Logger.new(log_path).tap do |l|
        l.level = log_level
        l.formatter = proc do |severity, time, group_name, message|
          "#{time},#{severity},##{Process.pid},#{group_name}: #{message}\n"
        end
      end
    end

    def redis
      @redis ||= @options[:redis] || Redis.new(url: redis_url || ENV.fetch("REDIS_URL"))
    end

    def concurrency
      @concurrency ||= @options[:concurrency] || [1, requests_per_second.ceil * CONCURRENCY_MULTIPLIER].max
    end

    def locks
      @locks ||= concurrency.times.map do |i|
        [redis_namespace, "#{lock_namespace}_#{i}"].compact.join(":")
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
          when :linear
            Strategy::Linear
          when :fibonacci
            Strategy::Fibonacci
          when :inverse_exponential
            Strategy::InverseExponential
          else
            retry_strategy
          end

        unless klass.is_a?(Class) && klass < Strategy::Base
          fail ConfigError, ":retry_strategy should be a class inheriting SlowDown::Strategy::Base"
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
