ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "minitest/reporters"
require "minitest/mock"
require "minitest/stub_const"
require "benchmark"
require "tempfile"
require "slow_down"

MiniTest::Reporters.use!(Minitest::Reporters::SpecReporter.new)
