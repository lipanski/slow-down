require_relative "test_helper"
require_relative "support/tolerance"

class TestMultipleGroups < MiniTest::Test
  include Support::Tolerance

  def setup
    @counter = Queue.new
    @threads = []
  end

  def teardown
    @threads.each(&:kill)
    SlowDown::Group.remove_all
  end

  def test_grouped_straight_runs
    SlowDown.config(:a) { |c| c.requests_per_second = 5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5 }

    elapsed_time = Benchmark.realtime do
      5.times do
        SlowDown.run(:a) { @counter << 1 }
        SlowDown.run(:b) { @counter << 1 }
      end
    end

    assert_in_delta(0.0, elapsed_time, TOLERANCE)
    assert_equal(10, @counter.size)
  end

  def test_grouped_throttled_runs
    SlowDown.config(:a) { |c| c.requests_per_second = 2; c.timeout = 1.5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5; c.timeout = 1.5 }

    3.times do
      @threads << Thread.new do
        SlowDown.run(:a) { @counter << 1 }
      end
    end

    9.times do
      @threads << Thread.new do
        SlowDown.run(:b) { @counter << 1 }
      end
    end

    elapsed_time = Benchmark.realtime { @threads.each(&:join) }

    assert_in_delta(1.0, elapsed_time, TOLERANCE * 3)
    assert_equal(12, @counter.size)
  end

  def test_grouped_throttled_runs_with_timeout
    SlowDown.config(:a) { |c| c.requests_per_second = 1; c.timeout = 0.5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 4; c.timeout = 1.2 }

    a_counter, b_counter = Queue.new, Queue.new

    2.times do
      @threads << Thread.new do
        SlowDown.run(:a) { a_counter << 1 }
      end
    end

    10.times do
      @threads << Thread.new do
        SlowDown.run(:b) { b_counter << 1 }
      end
    end

    sleep(0.2)
    assert_equal(1, a_counter.size)
    assert_equal(4, b_counter.size)

    sleep(1.0)
    assert_equal(1, a_counter.size)
    assert_equal(8, b_counter.size)

    elapsed_time = Benchmark.realtime { @threads.each(&:join) }
    assert_in_delta(0.0, elapsed_time, TOLERANCE)
    assert_equal(1, a_counter.size)
    assert_equal(8, b_counter.size)
  end

  def test_grouped_throttled_runs_with_raised_timeout
    SlowDown.config(:a) { |c| c.requests_per_second = 1; c.timeout = 0.5 }
    SlowDown.config(:b) { |c| c.requests_per_second = 4; c.timeout = 1.2; c.raise_on_timeout = true }

    a_counter, b_counter = Queue.new, Queue.new

    2.times do
      @threads << Thread.new do
        SlowDown.run(:a) { a_counter << 1 }
      end
    end

    10.times do
      @threads << Thread.new do
        SlowDown.run(:b) { b_counter << 1 }
      end
    end

    assert_raises(SlowDown::Timeout) do
      @threads.each(&:join)
    end

    assert_equal(1, a_counter.size)
    assert_equal(8, b_counter.size)
  end

  def test_grouped_truthy_free_checks
    SlowDown.config(:a) { |c| c.requests_per_second = 3 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5 }

    2.times do
      SlowDown.run(:a) { 1 }
    end

    4.times do
      SlowDown.run(:b) { 1 }
    end

    assert_equal(true, SlowDown.free?(:a))
    assert_equal(true, SlowDown.free?(:b))
  end

  def test_grouped_falsy_free_checks
    SlowDown.config(:a) { |c| c.requests_per_second = 3 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5 }

    3.times do
      SlowDown.run(:a) { 1 }
    end

    5.times do
      SlowDown.run(:b) { 1 }
    end

    assert_equal(false, SlowDown.free?(:a))
    assert_equal(false, SlowDown.free?(:b))
  end

  def test_grouped_mixed_free_checks
    SlowDown.config(:a) { |c| c.requests_per_second = 3 }
    SlowDown.config(:b) { |c| c.requests_per_second = 5 }

    3.times do
      SlowDown.run(:a) { 1 }
    end

    3.times do
      SlowDown.run(:b) { 1 }
    end

    assert_equal(false, SlowDown.free?(:a))
    assert_equal(true, SlowDown.free?(:b))
  end
end
