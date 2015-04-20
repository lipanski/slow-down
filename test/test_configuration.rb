require_relative "test_helper"

class TestConfigurations < MiniTest::Test
  def teardown
    SlowDown::Group.remove_all
  end

  def test_configure_same_group_twice
    SlowDown.config { |c| c.timeout = 999 }

    assert_raises(SlowDown::ConfigError) do
      SlowDown.run(timeout: 100)
    end
  end

  def test_redis_from_env_variable
    skip "todo: minitest mocking..."

    Object.stub_const(:ENV, { "REDIS_URL" => "redis://hello" }) do
      mock = MiniTest::Mock.new
      mock.expect(:call, true, [{ url: "redis://hello" }])

      Redis.stub(:new, mock) do
        config = SlowDown.config
        config.redis
      end

      mock.verify
    end
  end

  def test_redis_from_instance
    redis = Redis.new
    config = SlowDown.config do |c|
      c.redis = redis
    end

    assert_equal(redis, config.redis)
  end

  def test_redis_from_url
    skip "todo: minitest mocking..."

    config = SlowDown.config do |c|
      c.redis_url = "redis://hello"
    end
  end

  def test_requests_per_second_from_config
    SlowDown.config { |c| c.requests_per_second = 999 }

    assert_equal(999, SlowDown.config.requests_per_second)
  end

  def test_requests_per_second_from_run
    SlowDown.run(requests_per_second: 999) {}

    assert_equal(999, SlowDown.config.requests_per_second)
  end

  def test_timeout_from_config
    SlowDown.config { |c| c.timeout = 999 }

    assert_equal(999, SlowDown.config.timeout)
  end

  def test_timeout_from_run
    SlowDown.run(timeout: 999) {}

    assert_equal(999, SlowDown.config.timeout)
  end

  def test_retries_from_config
    SlowDown.config { |c| c.retries = 999 }

    assert_equal(999, SlowDown.config.retries)
  end

  def test_retries_from_run
    SlowDown.run(retries: 999) {}

    assert_equal(999, SlowDown.config.retries)
  end

  def test_concurrency_from_config
    SlowDown.config { |c| c.concurrency = 999 }

    assert_equal(999, SlowDown.config.concurrency)
  end

  def test_concurrency_from_run
    SlowDown.run(concurrency: 999) {}

    assert_equal(999, SlowDown.config.concurrency)
  end

  def test_concurrency_from_default_if_requests_per_second_below_1
    SlowDown.config { |c| c.requests_per_second = 0.5 }

    assert_equal(1, SlowDown.config.concurrency)
  end

  def test_concurrency_from_default_if_requests_per_second_above_1
    SlowDown.config { |c| c.requests_per_second = 999 }

    assert_equal(999, SlowDown.config.concurrency)
  end

  def test_locks
    SlowDown.config { |c| c.redis_namespace = :hello; c.lock_namespace = :world; c.concurrency = 3 }

    assert_equal(["hello:world_0", "hello:world_1", "hello:world_2"], SlowDown.config.locks)
  end

  def test_locks_from_default_and_group_name
    SlowDown.config(:hello) { |c| c.concurrency = 3 }

    assert_equal(["slow_down:hello_0", "slow_down:hello_1", "slow_down:hello_2"], SlowDown.config(:hello).locks)
  end

  def test_raise_on_timeout_from_config
    SlowDown.config { |c| c.raise_on_timeout = true }

    assert_equal(true, SlowDown.config.raise_on_timeout)
  end

  def test_raise_on_timeout_from_run
    SlowDown.run(raise_on_timeout: true) {}

    assert_equal(true, SlowDown.config.raise_on_timeout)
  end

  def test_logger
    skip "todo"
  end
end
