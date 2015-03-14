require "slow_down/strategy/base"

module SlowDown
  module Strategy
    class InverseExponential < Base
      def series
        n.times.map do |i|
          1 - Math::E ** (i + 1)
        end
      end
    end
  end
end
