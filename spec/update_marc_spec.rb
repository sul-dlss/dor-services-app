require 'spec_helper'

describe Dor::UpdateMarcRecordService do

  before :all do
    Dor::Config.release.write_marc_script = 'bin/write_marc_record_test'
    Dor::Config.release.symphony_path = './spec/fixtures/sdr-purl'
    Dor::Config.release.purl_base_uri = 'http://purl.stanford.edu'
  end

  context "for a druid without a catkey" do
    it 'does nothing' do
      druid='druid:aa222cc3333'
      setup_marc_record(druid,build_identity_metadata_without_ckey)
      expect(@umrs).to receive(:ckey).with(@dor_item).and_return(nil)
      expect(@umrs).not_to receive(:push_symphony_record)
      @umrs.update
    end
  end

  context "for a druid with a catkey" do
    it "executes the UpdateMarcRecordService push_symphony_record method" do
      druid='druid:bb333dd4444'
      setup_marc_record(druid,build_identity_metadata_with_ckey)
      expect(@umrs).to receive(:ckey).twice.with(@dor_item).and_return('8832162')
      expect(@umrs.generate_symphony_record).to eq("8832162\t#{druid.gsub('druid:','')}\t")
      expect(@umrs).to receive(:push_symphony_record)
      @umrs.update
    end
  end
end

def build_identity_metadata_with_ckey
  '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:bb333dd4444</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="catkey">8832162</otherId>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end

def build_identity_metadata_without_ckey
  '<identityMetadata>
  <sourceId source="sul">36105216275185</sourceId>
  <objectId>druid:aa222cc3333</objectId>
  <objectCreator>DOR</objectCreator>
  <objectLabel>A  new map of Africa</objectLabel>
  <objectType>item</objectType>
  <displayType>image</displayType>
  <adminPolicy>druid:dd051ys2703</adminPolicy>
  <otherId name="uuid">ff3ce224-9ffb-11e3-aaf2-0050569b3c3c</otherId>
  <tag>Process : Content Type : Map</tag>
  <tag>Project : Batchelor Maps : Batch 1</tag>
  <tag>LAB : MAPS</tag>
  <tag>Registered By : dfuzzell</tag>
  <tag>Remediated By : 4.15.4</tag>
  </identityMetadata>'
end
