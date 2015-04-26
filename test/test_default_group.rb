require_relative "test_helper"
require_relative "support/tolerance"

class TestDefaultGroup < MiniTest::Test
  include Support::Tolerance

  def setup
    @counter = Queue.new
  end

  def teardown
    SlowDown::Group.remove_all
  end

  def test_single_straight_run
    elapsed_time = Benchmark.realtime do
      SlowDown.run { @counter << 1 }
    end

    assert_in_delta(0.0, elapsed_time, TOLERANCE)
    assert_equal(1, @counter.size)
  end

  def test_multiple_straight_runs
    SlowDown.config { |c| c.requests_per_second = 5 }

    elapsed_time = Benchmark.realtime do
      5.times do
        SlowDown.run { @counter << 1 }
      end
    end

    assert_in_delta(0.0, elapsed_time, TOLERANCE)
    assert_equal(5, @counter.size)
  end

  def test_multiple_throttled_runs
    SlowDown.config do |c|
      c.requests_per_second = 2
      c.timeout = 5
    end

    elapsed_time = Benchmark.realtime do
      3.times do
        SlowDown.run { @counter << 1 }
      end
    end

    assert_equal(3, @counter.size)
    assert_in_delta(1.0, elapsed_time, TOLERANCE)
  end

  def test_multiple_throttled_runs_with_timeout
    SlowDown.config do |c|
      c.requests_per_second = 1
      c.timeout = 0.5
    end

    SlowDown.run { @counter << 1 }

    elapsed_time = Benchmark.realtime do
      SlowDown.run { @counter << 1 }
    end

    assert_in_delta(0.5, elapsed_time, TOLERANCE)
    assert_equal(1, @counter.size)
  end

  def test_multiple_throttled_runs_with_raised_timeout
    SlowDown.config do |c|
      c.requests_per_second = 1
      c.timeout = 0.5
      c.raise_on_timeout = true
    end

    SlowDown.run { @counter << 1 }

    assert_raises(SlowDown::Timeout) do
      SlowDown.run { @counter << 1 }
    end

    assert_equal(1, @counter.size)
  end

  def test_truthy_free_check
    SlowDown.config { |c| c.requests_per_second = 5 }

    4.times do
      SlowDown.run { 1 }
    end

    assert_equal(true, SlowDown.free?)
  end

  def test_falsy_free_check
    SlowDown.config { |c| c.requests_per_second = 5 }

    5.times do
      SlowDown.run { 1 }
    end

    assert_equal(false, SlowDown.free?)
  end

  def test_free_check_is_non_blocking
    SlowDown.config { |c| c.requests_per_second = 3 }

    3.times do
      SlowDown.run { 1 }
    end

    results = []

    elapsed_time = Benchmark.realtime do
      20.times do
        results << SlowDown.free?
      end
    end

    assert_in_delta(0.0, elapsed_time, TOLERANCE)
    assert_equal(20, results.select { |r| r == false }.size)
  end

  def test_free_check_consumes_the_resource
    SlowDown.config { |c| c.requests_per_second =  3 }

    2.times do
      SlowDown.run { 1 }
    end

    SlowDown.free?

    assert_equal(false, SlowDown.free?)
  end
end
