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

    assert_in_delta(0.0, elapsed_time, TOLERANCE)
    assert_equal(10, @counter)
  end

  def test_grouped_throttled_runs
    SlowDown.config(:a) { |c| c.requests_per_second = 2; c.timeout = 1.5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5; c.timeout = 1.5 }

    threads = []

    3.times do
      threads << Thread.new do
        SlowDown.run(:a) { @counter += 1 }
      end
    end

    9.times do
      threads << Thread.new do
        SlowDown.run(:b) { @counter += 1 }
      end
    end

    elapsed_time = Benchmark.realtime { threads.each(&:join) }

    assert_in_delta(1.0, elapsed_time, TOLERANCE * 2)
    assert_equal(12, @counter)
  end

  def test_grouped_throttled_runs_with_timeout
    SlowDown.config(:a) { |c| c.requests_per_second = 1; c.timeout = 0.5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 4; c.timeout = 1.2 }

    threads, a_counter, b_counter = [], 0, 0

    2.times do
      threads << Thread.new do
        SlowDown.run(:a) { a_counter += 1 }
      end
    end

    10.times do
      threads << Thread.new do
        SlowDown.run(:b) { b_counter += 1 }
      end
    end

    elapsed_time = Benchmark.realtime { threads.each(&:join) }

    assert_in_delta(1.2, elapsed_time, TOLERANCE * 2)
    assert_equal(1, a_counter)
    assert_equal(8, b_counter)
  end

  def test_grouped_throttled_runs_with_raised_timeout
    skip
  end
end
