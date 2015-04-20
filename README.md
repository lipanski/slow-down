# SlowDown

[![Build Status](https://travis-ci.org/lipanski/slow-down.svg?branch=master)](https://travis-ci.org/lipanski/slow-down)

## Why would you want to slow down your requests?!

Some APIs might be throttling your requests or your own infrastructure is not able to bear the load at peak times. It sometimes pays off to be patient, rather than show a *limit exceeded* error right away.

**SlowDown** delays a call up until the point where you can afford triggering it. It relies on a Redis lock so it should be able to handle a cluster of servers all going for the same resource. It's based on the `PX` and `NX` options of the Redis `SET` command, which should make it thread-safe. Note that these options were introduced with Redis version 2.6.12.

## Usage

```ruby
require "slow_down"

SlowDown.config do |c|
  c.requests_per_second = 10
  c.retries = 50 # times
  c.timeout = 5 # seconds
  c.raise_on_timeout = true # will raise SlowDown::Timeout
  c.redis_url = "redis://localhost:6379/0" # or set the REDIS_URL environment variable
end

100.times.do
  SlowDown.run do
    some_throttled_api_call # accepting only 10 req/sec
  end
end
```

## Polling Strategies

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

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/lipanski/slow_down/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
