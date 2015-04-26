if ["development", "test"].include?(ENV["RACK_ENV"])
  require "dotenv"
  Dotenv.load
end

require "slow_down/version"
require "slow_down/group"

module SlowDown
  module_function

  Timeout = Class.new(StandardError)
  ConfigError = Class.new(StandardError)

  def config(group_name = :default)
    group = Group.find_or_create(group_name)

    group.config.tap do |c|
      yield(c) if block_given?
    end
  end

  def groups
    Group.all
  end

  def run(*args, &block)
    find_or_create_group(*args).run(&block)
  end

  def free?(*args)
    find_or_create_group(*args).free?
  end

  def reset(group_name = :default)
    if group = Group.find(group_name)
      group.reset
    end
  end

  def find_or_create_group(*args)
    if args[0].is_a?(Hash)
      group_name = :default
      options    = args[0]
    else
      group_name = args[0] || :default
      options    = args[1] || {}
    end

    Group.find_or_create(group_name, options)
  end
end
