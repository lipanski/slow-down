require "minitest/autorun"
require "minitest/reporters"
require "slow_down"

MiniTest::Reporters.use!(Minitest::Reporters::SpecReporter.new)
