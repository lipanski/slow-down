require "redis"
require "slow_down/version"
require "slow_down/configuration"

module SlowDown
  module_function

  def config
    Configuration.instance.tap do |c|
      yield(c) if block_given?
    end
  end

  def configure(resource_count: 5, seconds: 20, timeout: 5, retries: 100, retry_strategy: nil, raise_on_timeout: false)
    self.resource_count = resource_count
    self.seconds = seconds
    self.timeout = timeout
    self.retries = retries
  end

  def redis
    @redis ||= Redis.new(url: "redis://localhost:6379/0")
  end

  def resource_count=(count)
    @resource_count = count
  end

  def seconds=(seconds)
    @seconds = seconds.to_f
  end

  def timeout=(timeout)
    @timeout = timeout.to_f
  end

  def retries=(retries)
    @retries = retries
  end

  def miliseconds_per_resource
    @miliseconds_per_resource ||= (@seconds * 1000 / @resource_count).round
  end

  def seconds_per_retry
    @timeout / @retries
  end

  def resources
    @resources ||= @resource_count.times.map { |i| "resource_#{i}" }
  end

  def free?
    resources.each do |key|
      if redis.set(key, 1, px: miliseconds_per_resource, nx: true)
        puts "#{key} locked for #{miliseconds_per_resource}"
        return true
      end
    end

    false
  end

  def wait
    puts "sleeping #{seconds_per_retry}"
    sleep(seconds_per_retry)
  end

  def run
    expires_at = Time.now + @timeout
    begin
      return yield if free?
      wait
    end until Time.now > expires_at
    puts "timeouted..."
  end
end
