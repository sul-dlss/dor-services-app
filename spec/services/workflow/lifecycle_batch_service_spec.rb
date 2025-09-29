# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::LifecycleBatchService do
  let(:druid) { 'druid:gv054hp4128' }

  describe '#milestones_map' do
    subject(:milestones_map) { described_class.milestones_map(druids: [druid, 'druid:bc123cd5678']) }

    before do
      create(:workflow_step,
             druid:,
             version: 2,
             process: 'publish',
             status: 'completed',
             lifecycle: 'published')
    end

    it 'returns a map of milestones' do
      expect(milestones_map).to match({
                                        druid => [{ milestone: 'published',
                                                    at: an_instance_of(ActiveSupport::TimeWithZone), version: '2' }]
                                      })
    end
  end
end
