module Support
  module Tolerance
    TOLERANCE = (RUBY_PLATFORM == "java") ? 0.1 : 0.05
  end
end
