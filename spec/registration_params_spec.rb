require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Dor::RegistrationParams do
  describe "#normalize" do
    it "cleans up the params hash passed in" do
      pending
      params = {
       :pid => 'dor:123' 
      }
      
      Dor::RegistrationParams.normalize(params).should == params
    end
    
    it "retrieves labels from the MetadataService when the label param == ':auto'" do
      pending
    end
    
    it "converts symphony :other_ids to barcodes and catkeys" do
      pending
    end
  end
end