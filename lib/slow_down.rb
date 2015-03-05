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

  def free?
    locks.each do |key|
      if redis.set(key, 1, px: config.miliseconds_per_request_per_lock, nx: true)
        puts "#{key} locked for #{config.miliseconds_per_request_per_lock}ms"
        return true
      end
    end

    false
  end

  def wait
    puts "sleeping #{config.seconds_per_retry}"
    sleep(config.seconds_per_retry)
  end

  def run
    expires_at = Time.now + config.timeout

    begin
      return yield if free?
      wait
    end until Time.now > expires_at

    raise Timeout if config.raise_on_timeout
  end
end

SlowDown.config do |c|
  c.requests_per_second = 2
  c.retries = 50
  c.timeout = 2
  c.raise_on_timeout = false
  c.redis_url = "redis://localhost:6379/0"
end
