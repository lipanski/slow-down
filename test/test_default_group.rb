require_relative "test_helper"

class TestDefaultGroup < MiniTest::Test
  def setup
    @counter = 0
  end

  def teardown
    SlowDown::Group.remove_all
  end

  def test_single_straight_run
    elapsed_time = Benchmark.realtime { SlowDown.run { @counter += 1 } }

    assert_in_delta(0.02, elapsed_time, 0.02)
    assert_equal(1, @counter)
  end

  def test_multiple_straight_runs
    SlowDown.config do |c|
      c.requests_per_second = 5
    end

    elapsed_time = Benchmark.realtime do
      5.times { SlowDown.run { @counter += 1 } }
    end

    assert_in_delta(0.02, elapsed_time, 0.02)
    assert_equal(5, @counter)
  end

  def test_multiple_throttled_runs
    SlowDown.config do |c|
      c.requests_per_second = 2
      c.timeout = 5
    end

    elapsed_time = Benchmark.realtime do
      3.times { SlowDown.run { @counter += 1 } }
    end

    assert_equal(3, @counter)
    assert_in_delta(1.0, elapsed_time, 0.05)
  end

  def test_multiple_throttled_runs_with_timeout
    SlowDown.config do |c|
      c.requests_per_second = 1
      c.timeout = 0.5
    end

    SlowDown.run { @counter += 1 }
    elapsed_time = Benchmark.realtime { SlowDown.run { @counter += 1 } }

    assert_in_delta(0.5, elapsed_time, 0.05)
    assert_equal(1, @counter)
  end

  def test_multiple_throttled_runs_with_raised_timeout
    SlowDown.config do |c|
      c.requests_per_second = 1
      c.timeout = 0.5
      c.raise_on_timeout = true
    end

    SlowDown.run { @counter += 1 }
    assert_raises(SlowDown::Timeout) { SlowDown.run { @counter += 1 } }

    assert_equal(1, @counter)
  end
end
