require "slow_down/strategy/base"

module SlowDown
  module Strategy
    class Linear < Base
      def self.aliases
        [:linear, :simple]
      end

      def series
        n.times.map { 1 }
      end
    end
  end
end
