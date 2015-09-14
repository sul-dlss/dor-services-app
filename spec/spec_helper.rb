require File.expand_path(File.dirname(__FILE__) + "/../config/boot")

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

TEST_WORKSPACE = (Dor::Config.stacks.local_workspace_root = 'tmp/dor/workspace')

def clean_workspace
  FileUtils.rm_rf Dir.glob(TEST_WORKSPACE + '/*')
end

def login
  authorize Dor::Config.dor.service_user, Dor::Config.dor.service_password
end