# frozen_string_literal: true

require "slow_down/strategy/base"

module SlowDown
  module Strategy
    class Linear < Base
      def series
        Array.new(n, 1)
      end
    end
  end
end
