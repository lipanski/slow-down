module SlowDown
  module Strategy
    class Base
      attr_reader :n, :max

      def initialize(n, max)
        @n, @max = n, max
      end

      def self.aliases
        fail NotImplemented
      end

      def series
        fail NotImplemented
      end

      def normalized_series
        sum = series.inject(:+)
        ratio = max.to_f / sum

        series.map { |el| el * ratio }
      end
    end
  end
end
