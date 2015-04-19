require_relative "test_helper"

class TestConfigurations < MiniTest::Test
  def teardown
    SlowDown::Group.remove_all
  end

  def test_redis_from_env_variable
    skip "todo"

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
    skip "todo"

    config = SlowDown.config do |c|
      c.redis_url = "redis://hello"
    end
  end
end
