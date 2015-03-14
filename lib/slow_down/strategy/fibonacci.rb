require "slow_down/strategy/base"

module SlowDown
  module Strategy
    class Fibonacci < Base
      def series
        (n - 2).times.each_with_object([1, 2]) do |_, arr|
          arr << arr[-2] + arr[-1]
        end
      end
    end
  end
end
