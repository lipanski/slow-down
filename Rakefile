# frozen_string_literal: true

require "rake"
require "rake/testtask"
require "bundler/gem_tasks"

task(default: ["rubocop", "test"])

desc "Run rubocop checks"
task :rubocop do
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
end

Rake::TestTask.new do |t|
  t.test_files = Dir.glob("test/**/test_*.rb")
end
