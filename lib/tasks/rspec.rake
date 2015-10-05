begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |spec|
    spec.pattern = 'spec/**/*_spec.rb'
    ENV['RACK_ENV'] = 'local'
  end

  task :default => [:spec]
rescue LoadError => e
end

