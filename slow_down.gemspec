# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "slow_down"
  spec.version       = "1.0.0"
  spec.authors       = ["Florin Lipan"]
  spec.email         = ["florinlipan@gmail.com"]

  spec.summary       = "A centralized Redis-based lock to help you wait on throttled resources"
  spec.description   = "A centralized Redis-based lock to help you wait on throttled resources"
  spec.homepage      = "https://github.com/lipanski/slow-down"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "redis"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "dotenv"
  spec.add_development_dependency "m"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "minitest-reporters"
  spec.add_development_dependency "minitest-stub-const"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rubocop"
end
