ENV['RACK_ENV'] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/boot")
require 'ruby-debug'

Spec::Runner.configure do |conf|
  conf.include Rack::Test::Methods
end