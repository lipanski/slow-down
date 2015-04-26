# SlowDown

[![Build Status](https://travis-ci.org/lipanski/slow-down.svg?branch=master)](https://travis-ci.org/lipanski/slow-down)

## Why would you want to slow down your requests?!

Some external APIs might be throttling your requests (or web scraping attempts) or your own infrastructure is not able to bear the load.
It sometimes pays off to be patient...

**SlowDown** delays a call up until the point where you can afford to trigger it.
It relies on a Redis lock so it should be able to handle a cluster of servers all going for the same resource.
It's based on the `PX` and `NX` options of the Redis `SET` command, which should make it thread-safe.
Note that these options were introduced with Redis version 2.6.12.

## Usage

### Basic

```ruby
require "slow_down"

SlowDown.config do |c|
  c.requests_per_second = 10
  c.retries = 50 # times
  c.timeout = 5 # seconds
  c.raise_on_timeout = true # will raise SlowDown::Timeout
  c.redis_url = "redis://localhost:6379/0" # or set the REDIS_URL environment variable
end

SlowDown.run do
  some_throttled_api_call # accepting only 10 req/sec
end
```

### Groups

**SlowDown** can be configured for individual groups, which can be run in isolation:

```ruby
SlowDown.config(:github) do |c|
  c.requests_per_second = 50
  c.timeout = 10
end

SlowDown.config(:twitter) do |c|
  c.requests_per_second = 10
  c.timeout = 1
end

# Acquire a lock for the :github group
SlowDown.run(:github) { ... }

# Acquire a lock for the :twitter group
SlowDown.run(:twitter) { ... }
```

### Retrieve configuration

When called without a block, `SlowDown.config` will return the configuration of the *default* group.
In order to fetch the configuration of a different group use `SlowDown.config(:group_name)`.

### Inline configuration

**SlowDown** may also be configured directly within the `SlowDown.run` call:

```ruby
# Configure the :default group and run a call
SlowDown.run(requests_per_second: 5, timeout: 15, raise_on_timeout: true) do
  # ...
end

# Configure a different group and run a call within that group
SlowDown.run(:my_group, requests_per_second: 2, timeout: 1) do
  # ...
end
```

### Defaults & available options

```ruby
SlowDown.config do |c|
  # The allowed number of calls per second.
  c.requests_per_second = 10

  # The number of seconds during which SlowDown will try and acquire the resource
  # for a given call.
  c.timeout = 5

  # Whether to raise an error when the timeout was reached and the resource could
  # not be acquired.
  # Raises SlowDown::Timeout.
  c.raise_on_timeout = false

  # How many retries should be performed til the timeout is reached.
  c.retries = 30

  # The algorithm used to schedule the amount of time to wait between retries.
  # Available strategies: :linear, :inverse_exponential, :fibonacci or a class
  # extending SlowDown::Strategy::Base.
  c.retry_strategy = :linear

  # Redis can be configured either directly, by setting a Redis instance to this
  # variable, or via the REDIS_URL environment variable or via the redis_url
  # setting.
  c.redis = nil

  # Configure Redis via the instance URL.
  c.redis_url = nil

  # The Redis namespace to apply to all locks.
  c.redis_namespace = :slow_down

  # The namespace to apply to the default group.
  # Individual groups will overwrite this with the group name.
  c.lock_namespace = :default

  # Set this to a path or file descriptor in order to log to file.
  c.log_path = STDOUT

  # By default, the SlowDown logger is disabled.
  # Set this to Logger::DEBUG, Logger::INFO or Logger::ERROR for logging various
  # runtime information.
  c.log_level = Logger::UNKNOWN
end
```

### Non-blocking checks

A call to `.run` will halt until the resource is either acquired or the timeout kicks in.
In order to make a non-blocking check, you can use the `SlowDown.free?` method.

```ruby
SlowDown.config do |c|
  c.requests_per_second = 2
end

SlowDown.free? # true
SlowDown.free? # true
SlowDown.free? # false (won't wait)
sleep(1)
SlowDown.free? # true
```

The `SlowDown.free?` method also works with **groups** and **inline configuration**:

```ruby
def register_user(name, address, phone)
  user.name = name

  # Optional: geocode address, if we didn't exceed the request limit
  if SlowDown.free?(:geocoding, requests_per_second: 5)
    user.coordinates = geocode(address)
  end

  # Optional: send SMS, if we didn't exceed the request limit
  if SlowDown.free?(:sms, requests_per_second: 10)
    send_sms(phone)
  end

  user.save
end
```

### Resetting the locks

If you ever need to reset the locks, you can do that for any group by calling:

```ruby
SlowDown.reset(:group_name)
```

### Polling strategies

When a request is placed that can't access the lock right away, **SlowDown** puts it to sleep and schedules it to wake up & try again for the amount of retries configured by the user (defaulting to 30 retries).

The spread of these *retry sessions* can be linear (default behaviour) or non-linear - in case you want to simulate different strategies:

1. **FIFO**: Inverse exponential series - set `SlowDown.config { |c| c.retry_strategy = :inverse_exponential }`
2. **LIFO**: Fibonacci series - set `SlowDown.config { |c| c.retry_strategy = :fibonacci }`

These polling strategies are just a proof of concept and their behaviour relies more on probabilities.

## Inspiration

- [Distributed locks using Redis](https://engineering.gosquared.com/distributed-locks-using-redis)
- [Redis SET Documentation](http://redis.io/commands/set)
- [mario-redis-lock](https://github.com/marioizquierdo/mario-redis-lock)
- [redlock-rb](https://github.com/antirez/redlock-rb)

## Quotes

- *It's like sleep but more classy*
- *It's like sleep but over-engineered*
- *SlowHand*

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/lipanski/slow_down/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
