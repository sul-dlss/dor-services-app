require File.dirname(__FILE__) + '/config/boot.rb'

use Rack::CommonLogger, LyberCore::Log.log
use Rack::ShowExceptions
run Dor::DorServicesApi