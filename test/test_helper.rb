ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "benchmark"
require "slow_down"

MiniTest::Reporters.use!(Minitest::Reporters::SpecReporter.new)
