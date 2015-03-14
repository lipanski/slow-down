require "spec_helper"
require "benchmark"

def cleanup
  around do |example|
    SlowDown.reset
    example.run
    SlowDown.reset
  end
end

def place_call
  SlowDown.run { 1 }
end

describe SlowDown do
  context "with a default configuration" do
    before do
      SlowDown.config do |c|
        c.requests_per_second = 111
        c.timeout = 111
        c.retries = 111
        c.concurrency = 111
        c.redis_url = "redis://111"
      end
    end

    it "" do

    end
  end

  context "with a request-specific configuration" do
    before do
      SlowDown.config do |c|
        c.requests_per_second = 111
        c.timeout = 111
        c.retries = 111
        c.concurrency = 111
        c.redis_url = "redis://111"
      end

      SlowDown.config(:api) do |c|
        c.requests_per_second = 222
        c.timeout = 222
        c.retries = 222
        c.concurrency = 222
        c.redis_url = "redis://222"
      end
    end
  end

  context "with a run-specific configuration" do
    before do
      SlowDown.config do |c|
        c.requests_per_second = 111
        c.timeout = 111
        c.retries = 111
        c.concurrency = 111
        c.redis_url = "redis://111"
      end

      SlowDown.config(:api) do |c|
        c.requests_per_second = 222
        c.timeout = 222
        c.retries = 222
        c.concurrency = 222
        c.redis_url = "redis://222"
      end
    end

    let(:run_config) do
      { requests_per_second: 333, timeout: 333, retries: 333, concurrency: 333, redis_url: "redis://222" }
    end

    # it "" do
    #   SlowDown.run(run_config) { 1 }
    # end
  end

  context "when capped at 2 requests per second, over two locks and with a timeout of 2 seconds" do
    cleanup

    before do
      SlowDown.config do |c|
        c.requests_per_second = 2
        c.timeout = 2
        c.retries = 10
        c.concurrency = 2
        c.log_level = ENV["DEBUG"] ? Logger::DEBUG : nil
      end
    end

    context "when there were no previous calls" do
      it "performs the block" do
        expect(place_call).to eq(1)
      end

      it "makes the call instantly" do
        expect(Benchmark.realtime { place_call }).to be < 0.001
      end
    end

    context "when previous calls have been made but within requests_per_second" do
      before do
        place_call
      end

      it "performs the block" do
        expect(place_call).to eq(1)
      end

      it "makes the call instantly" do
        expect(Benchmark.realtime { place_call }).to be < 0.001
      end
    end

    context "when 2 previous calls have been made but one second before" do
      before do
        2.times { place_call }
        sleep(1)
      end

      it "performs the block" do
        expect(place_call).to eq(1)
      end

      it "makes the call instantly" do
        expect(Benchmark.realtime { place_call }).to be < 0.01
      end
    end

    context "when 2 previous calls have been made within the current second" do
      before do
        2.times { place_call }
      end

      it "performs the block eventually because the timeout is generous enough" do
        expect(place_call).to eq(1)
      end

      it "makes the call after about 1 second" do
        expect(Benchmark.realtime { place_call }).to be_within(0.015).of(1.0)
      end
    end

    context "when 4 previous calls have been made within the current second" do
      before do
        4.times do
          Thread.new { place_call }
        end

        # This is the :linear strategy - everyone gets the same chances of acquiring the lock.
        # Sleeping here ensures that the tested call doesn't get that chance.
        sleep(0.1)
      end

      it "won't perform the block because of the 2 second timeout" do
        expect(place_call).to be_nil
      end

      it "returns nil after about 2 seconds" do
        expect(Benchmark.realtime { place_call }).to be_within(0.015).of(2.0)
      end
    end
  end
end
