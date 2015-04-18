if [nil, "development", "test"].include?(ENV["RACK_ENV"])
  require "dotenv"
  Dotenv.load
end

require "slow_down/version"
require "slow_down/group"

module SlowDown
  module_function

  Timeout = Class.new(StandardError)

  def config(group_name = :default)
    group = Group.find_or_create(group_name)

    group.config.tap do |c|
      yield(c) if block_given?
    end
  end

  def groups
    Group.all
  end

  def run(group_name = :default, options = {}, &block)
    Group.find_or_create(group_name, options).run(&block)
  end

  def reset(group_name = :default)
    group = Group.find(group_name)
    group.reset if group
  end
end
