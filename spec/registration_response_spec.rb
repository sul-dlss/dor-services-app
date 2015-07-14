require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RegistrationResponse do
  
  describe "self marshalling" do
    
    before(:each) do
      @params = {
        :object_type => 'item', 
        :content_model => 'googleScannedBook', 
        :admin_policy => 'druid:fg890hi1234', 
        :label => 'Google : Scanned Book 12345', 
        :agreement_id => 'druid:apu999blr', 
        :source_id => { :barcode => 9191919191 }, 
        :other_ids => { :catkey => '000', :uuid => '111' }, 
        :tags => ['Google : Google Tag!','Google : Other Google Tag!'],
        :location => 'http://fedora.url', 
        :pid => 'druid:xx123'
      }
      
      @resp = Dor::RegistrationResponse.new(@params)
    end
    
    it "to_xml marshalls to xml" do
      skip
    end
    
    it "to_json marshalls to json" do
      j = @resp.to_json
      expect(@params).to eq(JSON.parse(j, :symbolize_names => true))
    end
    
    it "to_text returns just the pid" do
      expect(@resp.to_txt).to eq('druid:xx123')
    end
  end
end
