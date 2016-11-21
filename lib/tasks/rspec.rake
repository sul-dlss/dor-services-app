begin
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new

  task default: [:spec, :rubocop]
rescue LoadError
end
