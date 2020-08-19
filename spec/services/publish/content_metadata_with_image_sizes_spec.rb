# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Publish::ContentMetadataWithImageSizes do
  subject(:service) { described_class.new(item.contentMetadata) }

  let(:item) { instantiate_fixture('druid:cg767mn6478', Dor::Item) }
  let(:response) do
    [
      {"druid"=>"druid:cg767mn6478",
    "filename"=>"2542A.tif",
    "filetype"=>"fmt/353",
    "mimetype"=>"image/tiff",
    "bytes"=>46135534,
    "file_modification"=>"2020-08-13T16:28:56.690Z",
    "image_metadata"=>{"width"=>4484, "height"=>5641}},
    {"druid"=>"druid:cg767mn6478",
    "filename"=>"2542A.jp2",
    "filetype"=>"fmt/353",
    "mimetype"=>"image/tiff",
    "bytes"=>46135534,
    "file_modification"=>"2020-08-13T16:28:56.690Z",
    "image_metadata"=>{"width"=>7000, "height"=>8000}},
  ].to_json
  end
  before do
    stub_request(:get, 'http://metadata.stanford.edu:8080/v1/technical-metadata/druid/druid:cg767mn6478')
      .with(
        headers: {
          'Accept' => 'application/json',
          'Authorization' => 'Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhcmdvLXRlc3QifQ.nhJQsj8V98agZxzDP2OSCVPkIb70yE9_dyLUiTzcKko'
        }
      ).to_return(status: 200, body: response, headers: {})
  end

  it 'replaces imageData nodes with values from technical_metadata service' do
    expect(service.to_xml).to include '<imageData width="4484" height="5641"/>'
    expect(service.to_xml).to include '<imageData width="7000" height="8000"/>'
  end
end
