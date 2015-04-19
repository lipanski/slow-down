require_relative "test_helper"

class TestMultipleGroups < MiniTest::Test
  def setup
    @counter = 0
  end

  def teardown
    SlowDown::Group.remove_all
  end

  def test_grouped_straight_runs
    skip
  end

  def test_grouped_throttled_runs
    skip
  end

  def test_grouped_throttled_runs_with_timeout
    skip
  end

  def test_grouped_throttled_runs_with_raised_timeout
    skip
  end
end
