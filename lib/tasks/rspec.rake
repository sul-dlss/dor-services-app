# frozen_string_literal: true

begin
  require 'rspec/core/rake_task'
  require 'rubocop/rake_task'

  RuboCop::RakeTask.new(:rubocop) do |task|
    task.fail_on_error = true
  end

  # Clear the default task injected by rspec
  task(:default).clear

  task default: [:rubocop, :spec]
rescue LoadError
end
