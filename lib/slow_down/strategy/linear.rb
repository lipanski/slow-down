require "slow_down/strategy/base"

module SlowDown
  module Strategy
    class Linear < Base
      def series
        n.times.map { 1 }
      end
    end
  end
end
