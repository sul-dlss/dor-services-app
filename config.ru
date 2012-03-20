require File.dirname(__FILE__) + '/config/boot.rb'

use Rack::CommonLogger, LyberCore::Log.log
run Dor::DorServicesApi