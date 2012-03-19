environment = ENV["RACK_ENV"] ||= "development"

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV["RACK_ENV"].to_sym)

$:.unshift File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))
require 'dor-services'
require 'lyber_core'

require 'grape_json_parse'
require 'dor_services_app'
require 'registration_response'
require 'registration_params'

LyberCore::Log.set_logfile(File.join(File.dirname(__FILE__), "..", "log", "dor-services-app.log"))
ENV[rack.logger] = LyberCore::Log.logfile
if(ENV["RACK_ENV"] == "production")
  LyberCore::Log.set_level(1)
else
  LyberCore::Log.set_level(0)
end

env_file = File.expand_path(File.dirname(__FILE__) + "/environments/#{environment}")
require env_file