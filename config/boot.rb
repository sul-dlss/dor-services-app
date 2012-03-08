environment = ENV["RACK_ENV"] ||= "development"

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV["RACK_ENV"].to_sym)

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
Dir["./lib/**/*.rb"].each { |f| require f }

require 'dor-services'

env_file = File.expand_path(File.dirname(__FILE__) + "/environments/#{environment}")
require env_file