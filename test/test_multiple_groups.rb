require_relative "test_helper"
require_relative "support/tolerance"

class TestMultipleGroups < MiniTest::Test
  include Support::Tolerance

  def setup
    @counter = 0
  end

  def teardown
    SlowDown::Group.remove_all
  end

  def test_grouped_straight_runs
    SlowDown.config(:a) { |c| c.requests_per_second = 5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5 }

    elapsed_time = Benchmark.realtime do
      5.times do
        SlowDown.run(:a) { @counter += 1 }
        SlowDown.run(:b) { @counter += 1 }
      end
    end

    assert_in_delta(0.0, elapsed_time,TOLERANCE)
    assert_equal(10, @counter)
  end

  def test_grouped_throttled_runs
    SlowDown.config(:a) { |c| c.requests_per_second = 2; c.timeout = 1.5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5; c.timeout = 1.5 }

    threads = []

    3.times do
      threads << Thread.new { SlowDown.run(:a) { @counter += 1 } }
    end

    7.times do
      threads << Thread.new { SlowDown.run(:b) { @counter += 1 } }
    end

    elapsed_time = Benchmark.realtime do
      threads.each(&:join)
    end

    assert_in_delta(1.0, elapsed_time, TOLERANCE * 2)
    assert_equal(10, @counter)
  end

  def test_grouped_throttled_runs_with_timeout
    skip
  end

  def test_grouped_throttled_runs_with_raised_timeout
    skip
  end
end
