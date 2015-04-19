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
    skip "TODO: minitest mocking Y U NO work"

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
    skip "TODO: minitest mocking Y U NO work"

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
end
