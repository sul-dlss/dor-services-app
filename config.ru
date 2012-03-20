require File.dirname(__FILE__) + '/config/boot.rb'

$stdout.reopen(LyberCore::Log.logfile)
$stderr.reopen(LyberCore::Log.logfile)

use Rack::CommonLogger, LyberCore::Log.log
use Rack::ShowExceptions
run Dor::DorServicesApi