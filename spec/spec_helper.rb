require File.expand_path(File.dirname(__FILE__) + '/../config/boot')

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

def setup_marc_record(druid,xml)
  @dor_item=double(Dor::Item)
  @identityMetadataXML = Dor::IdentityMetadataDS.new
  allow(@identityMetadataXML).to receive_messages(:ng_xml => Nokogiri::XML(xml))
  allow(@dor_item).to receive_messages(
    :id=>druid,
    :released_for=>{},
    :datastreams => {"identityMetadata"=>@identityMetadataXML},
    :identityMetadata => @identityMetadataXML,
    :remove_druid_prefix=>druid.gsub('druid:','')
  )
  @umrs=Dor::UpdateMarcRecordService.new @dor_item
end

require 'fakeweb'