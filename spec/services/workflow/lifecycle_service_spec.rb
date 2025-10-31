# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Workflow::LifecycleService do
  let(:druid) { 'druid:gv054hp4128' }

  describe '#lifecycle_xml' do
    subject(:xml) { described_class.lifecycle_xml(druid:) }

    let(:expected_xml) do
      Nokogiri::XML(
        <<~XML
          <?xml version="1.0" ?>
            <lifecycle objectId="druid:gv054hp4128">
              <milestone date="2012-01-27T05:06:54+00:00" version="2">published</milestone>
            </lifecycle>
          </xml>
        XML
      )
    end

    before do
      create(:workflow_step,
             druid:,
             version: 2,
             process: 'publish',
             status: 'completed',
             lifecycle: 'published',
             completed_at: DateTime.parse('2012-01-27T05:06:54+00:00'))
    end

    it 'returns the lifecycle XML' do
      expect(xml).to be_equivalent_to(expected_xml)
    end
  end

  describe '#milestone?' do
    subject(:service) { described_class.new(druid: druid, version:) }

    let(:version) { nil }

    before do
      create(:workflow_step,
             druid:,
             version: 3,
             process: 'publish',
             status: 'completed',
             lifecycle: 'published')
      create(:workflow_step,
             druid:,
             version: 3,
             process: 'end-accession')
    end

    context 'when checking for a milestone in a specific version' do
      context 'when the milestone exists' do
        let(:version) { 3 }

        it 'returns true' do
          expect(service.milestone?(milestone_name: 'published')).to be true
        end
      end

      context 'when the milestone does not exist' do
        let(:version) { 2 }

        it 'returns false' do
          expect(service.milestone?(milestone_name: 'published')).to be false
        end
      end
    end

    context 'when not checking for a specific version' do
      context 'when the milestone exists' do
        it 'returns true' do
          expect(service.milestone?(milestone_name: 'published'))
            .to be true
        end
      end

      context 'when the milestone does not exist' do
        it 'returns false' do
          expect(service.milestone?(milestone_name: 'accessioned'))
            .to be false
        end
      end
    end
  end

  describe '#milestones' do
    subject(:milestones) { service.milestones }

    let(:service) { described_class.new(druid: druid, version:) }

    let(:version) { nil }

    before do
      create(:workflow_step,
             druid:,
             version: 2,
             process: 'publish',
             status: 'completed',
             lifecycle: 'published')

      create(:workflow_step,
             druid:,
             version: 1,
             process: 'start-accession',
             status: 'completed',
             lifecycle: 'submitted')
    end

    context 'when a version is specified' do
      let(:version) { 2 }

      it 'returns the milestones for that version only' do
        expect(milestones.length).to eq 1
      end
    end

    context 'when no version is specified' do
      it 'returns the milestones for all versions' do
        expect(milestones.length).to eq 2
        expect(milestones.last[:milestone]).to eq('published')
        expect(milestones.last[:version]).to eq('2')
      end
    end
  end
end
