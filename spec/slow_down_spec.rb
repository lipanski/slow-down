require "spec_helper"

describe SlowDown do
  context "basic" do
    around do |example|
      SlowDown.config.redis.flushdb
      example.run
      SlowDown.config.redis.flushdb
    end

    before do
      SlowDown.config do |c|
        c.requests_per_second = 5
        c.concurrency = 1
        c.retries = 0
        c.timeout = 0.001
      end
    end

    it "performs the block if there's nothing else in the queue" do
      expect(SlowDown.run { 1 }).to eq(1)
    end

    it "doesn't perform the block if there's something else in the queue" do
      SlowDown.run { 1 }
      expect(SlowDown.run { 1 }).to be_nil
    end
  end
end
