require "slow_down/strategy/base"

module SlowDown
  module Strategy
    class Fibonacci < Base
      def series
        n.times.map { |int| fibonacci(int) }
      end

      private

      PHI = 1.6180339887498959
      PSI = 1.1708203932499368
      TAU = 0.5004471413430931

      def fibonacci(n)
        (PHI**n * PSI + TAU).to_i
      end
    end
  end
end
