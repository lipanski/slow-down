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

  def run(first = :default, second = {}, &block)
    if first.is_a?(Hash) && second.empty?
      group_name, options = :default, first
    else
      group_name, options = first, second
    end

    Group.find_or_create(group_name, options).run(&block)
  end

  def reset(group_name = :default)
    if group = Group.find(group_name)
      group.reset
    end
  end
end
