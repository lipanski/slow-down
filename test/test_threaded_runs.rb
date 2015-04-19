class TestThreadedRuns < MiniTest::Test
  def setup
    @counter = 0
  end

  def teardown
    SlowDown::Group.remove_all
  end

  def test_threaded_straight_runs
    skip
  end

  def test_threaded_throttled_runs
    skip
  end

  def test_threadded_throttled_runs_with_timeout
    skip
  end
end
