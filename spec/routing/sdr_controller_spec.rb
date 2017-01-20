require 'rails_helper'

RSpec.describe SdrController, type: :routing do
  describe 'routing' do
    it 'routes to #file_content' do
      expect(get: '/v1/sdr/objects/druid:mk420bs7601/content/00004692.tif')
        .to route_to('sdr#file_content', druid: 'druid:mk420bs7601', filename: '00004692.tif')
    end

    it 'routes to #ds_metadata' do
      expect(get: '/v1/sdr/objects/druid:sg651cq5818/metadata/technicalMetadata.xml')
        .to route_to('sdr#ds_metadata', druid: 'druid:sg651cq5818', dsname: 'technicalMetadata.xml')
    end

    it 'routes to #ds_manifest' do
      expect(get: '/v1/sdr/objects/druid:sg651cq5818/manifest/signatureCatalog.xml')
        .to route_to('sdr#ds_manifest', druid: 'druid:sg651cq5818', dsname: 'signatureCatalog.xml')
    end
  end
end
