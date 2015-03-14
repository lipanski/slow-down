# SlowDown

## Why would you want to slow down your requests?!

Some APIs might be throttling your requests or your own infrastructure is not able to bear the load at peak times. It sometimes pays off to be patient, rather than produce an error page right away.

**SlowDown** delays a call up until the point where you can afford triggering it. It relies on a Redis lock so it should be able to handle a cluster of servers and it's based on the `PX` and `NX` options of the Redis `SET` command, which should make it thread-safe. Note that these options were introduced with Redis version 2.6.12.

## Usage

```ruby
require "slow_down"

SlowDown.config do |c|
  c.requests_per_second = 10
  c.retries = 50 # times
  c.timeout = 5 # seconds
  c.raise_on_timeout = true # will raise SlowDown::Timeout
  c.redis_url = "redis://localhost:6379/0"
end

100.times.do
  SlowDown.run do
    some_throttled_api_call # accepting only 10 req/sec
  end
end
```

## Inspiration

- [Distributed locks using Redis](https://engineering.gosquared.com/distributed-locks-using-redis)
- [Redis SET Documentation](http://redis.io/commands/set)
- [mario-redis-lock](https://github.com/marioizquierdo/mario-redis-lock)
- [redlock-rb](https://github.com/antirez/redlock-rb)

## TODO

-[ ] simple lock
-[ ] FIFO strategy
-[ ] LIFO strategy  

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/slow_down/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
