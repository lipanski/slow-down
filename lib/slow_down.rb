if [nil, "development", "test"].include?(ENV["RACK_ENV"])
  require "dotenv"
  Dotenv.load
end

require "slow_down/version"
require "slow_down/configuration"

module SlowDown
  module_function

  Timeout = Class.new(StandardError)

  def config
    Configuration.instance.tap do |c|
      yield(c) if block_given?
    end
  end

  def locks
    config.locks
  end

  def redis
    config.redis
  end

  def logger
    config.logger
  end

  def free?
    locks.each do |key|
      if redis.set(key, 1, px: config.miliseconds_per_request_per_lock, nx: true)
        logger.debug("#{key} locked for #{config.miliseconds_per_request_per_lock}ms")
        return true
      end
    end

    false
  end

  def postpone
    logger.debug("sleeping for #{config.seconds_per_retry * 1000}ms")
    sleep(config.seconds_per_retry)
  end

  def run
    expires_at = Time.now + config.timeout
    logger.debug("call expires at #{expires_at}ms")

    begin
      return yield if free?
      postpone
    end until Time.now > expires_at

    raise Timeout if config.raise_on_timeout
  end
end
