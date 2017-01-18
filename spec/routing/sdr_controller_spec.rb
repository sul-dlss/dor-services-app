require 'rails_helper'

RSpec.describe SdrController, type: :routing do
  describe 'routing' do
    it 'routes to #content' do
      expect(get: '/v1/sdr/objects/druid:mk420bs7601/content/00004692.tif')
        .to route_to('sdr#file_content', druid: 'druid:mk420bs7601', filename: '00004692.tif')
    end
  end
end
