require 'rails_helper'

RSpec.describe VersionsController, type: :routing do
  describe 'routing' do
    it 'routes to #create' do
      expect(post: '/v1/objects/druid:mk420bs7601/versions')
        .to route_to('versions#create', object_id: 'druid:mk420bs7601')
    end
  end
end
