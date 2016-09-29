ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'bundler/setup'

Bundler.require(:default, ENV['RACK_ENV'].to_sym)

$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'grape_overrides'
require 'dor_services_app'
require 'registration_response'
require 'update_marc_record_service'

# Override from lyber-core gem so that we can access the log object in the config.ru
module LyberCore
  class LyberCore::Log
    def Log.log
      @@log
    end
  end
end

# Alias Logger#write to #<< in order for Rack::CommonLogger to use in config.ru
class ::Logger; alias_method :write, :<<; end

LyberCore::Log.set_logfile(File.join(File.dirname(__FILE__), '..', 'log', 'dor-services-app.log'))
LyberCore::Log.set_level(ENV['RACK_ENV'] == 'production' ? 1 : 0)

env_file = File.expand_path(File.dirname(__FILE__) + "/environments/#{ENV['RACK_ENV']}")
require env_file
