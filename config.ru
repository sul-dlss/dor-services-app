require File.dirname(__FILE__) + '/config/boot.rb'

use Rack::CommonLogger, LyberCore::Log.logfile
run Dor::DorServicesApi