# frozen_string_literal: true

module SlowDown
  module Strategy
    class Base
      attr_reader :n, :max

      def initialize(n, max) # rubocop:disable Naming/MethodParameterName
        @n = n
        @max = max
      end

      def series
        raise NotImplemented
      end

      def normalized_series
        sum = series.inject(:+)
        ratio = max.to_f / sum

        series.map { |el| el * ratio }
      end
    end
  end
end
