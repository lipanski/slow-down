require "slow_down/configuration"

module SlowDown
  class Group
    def self.all
      @groups || {}
    end

    def self.find(name)
      all[name]
    end

    def self.create(name, options = {})
      @groups ||= {}
      @groups[name] = Group.new(name, options)
    end

    def self.find_or_create(name, options = {})
      if all[name] && !options.empty?
        all[name].config.logger.error(name) { "Group #{name} has already been configured elsewhere" }
        fail ConfigError, "Group #{name} has already been configured elsewhere - you may not override configurations"
      end

      all[name] || create(name, options)
    end

    def self.remove(group_name)
      return unless group = Group.find(group_name)

      group.reset
      @groups.delete(group_name)
    end

    def self.remove_all
      all.each_value(&:remove)
    end

    attr_reader :name, :config

    def initialize(name, options = {})
      @name = name
      @config = Configuration.new({ lock_namespace: name }.merge(options))
    end

    def run
      expires_at, iteration = Time.now + config.timeout, 0
      config.logger.info(name) { "Run attempt initiatied, times out at #{expires_at}" }

      begin
        return yield if free?
        wait(iteration += 1)
      end until Time.now > expires_at

      config.logger.info(name) { "Run attempt timed out" }
      if config.raise_on_timeout
        config.logger.error(name) { "Timeout error raised" }
        raise Timeout
      end
    end

    def free?
      config.locks.each do |key|
        if config.redis.set(key, 1, px: config.miliseconds_per_request_per_lock, nx: true)
          config.logger.info(name) { "Lock #{key} was acquired for #{config.miliseconds_per_request_per_lock}ms" }
          return true
        end
      end

      false
    end

    def reset
      config.locks.each { |key| config.redis.del(key) }
    end

    def remove
      Group.remove(@name)
    end

    private

    def wait(iteration)
      config.logger.debug(name) { "Sleeping for #{config.seconds_per_retry(iteration) * 1000}ms" }
      sleep(config.seconds_per_retry(iteration))
    end
  end
end
