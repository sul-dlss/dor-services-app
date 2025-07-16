# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowLifecycleService do
  let(:ng_xml) { Nokogiri::XML(xml) }
  let(:xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
        <lifecycle objectId="druid:gv054hp4128">
          <milestone date="2012-01-26T21:06:54-0800" version="2">published</milestone>
        </lifecycle>
      </xml>
    XML
  end

  let(:workflow_client) { instance_double(Dor::Workflow::Client) }
  let(:druid) { 'druid:gv054hp4128' }

  describe '#lifecycle_xml' do
    context 'when local_wf is disabled' do
      let(:workflow_client) { instance_double(Dor::Workflow::Client) }

      before do
        allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
        allow(workflow_client).to receive(:query_lifecycle).and_return(ng_xml)
      end

      it 'returns the lifecycle XML' do
        expect(described_class.lifecycle_xml(druid:, version: 3, active_only: true)).to eq ng_xml

        expect(workflow_client).to have_received(:query_lifecycle).with(druid, version: 3, active_only: true)
      end
    end

    context 'when local_wf is enabled' do
      subject(:xml) { described_class.lifecycle_xml(druid: druid, version:, active_only:) }

      let(:version) { 2 }
      let(:active_only) { false }

      let(:returned_milestones) { xml.xpath('//lifecycle/milestone') }
      let(:returned_milestone_versions) { returned_milestones.map { |node| node.attr('version') } }
      let(:returned_milestone_text) { returned_milestones.map(&:text) }
      let(:druid) { wf.druid }

      before do
        allow(Settings.enabled_features).to receive(:local_wf).and_return(true)
      end

      context 'when active-only is set' do
        let(:active_only) { true }
        let(:wf) do
          # This should not appear in the results if they want active-only
          create(:workflow_step,
                 process: 'start-accession',
                 version: 1,
                 status: 'waiting',
                 lifecycle: 'submitted')
        end

        context 'when all steps in the current version are complete' do
          before do
            create(:workflow_step,
                   druid:,
                   version: 2,
                   process: 'start-accession',
                   status: 'completed',
                   lifecycle: 'submitted')

            # This is not a lifecycle event, so it shouldn't display.
            create(:workflow_step,
                   druid:,
                   version: 2,
                   process: 'technical-metadata',
                   status: 'completed')
          end

          it 'draws an empty set of milestones' do
            expect(returned_milestone_versions).to eq []
          end
        end

        context 'when some steps in the current version are not complete' do
          before do
            create(:workflow_step,
                   druid:,
                   version: 2,
                   process: 'start-accession',
                   status: 'completed',
                   lifecycle: 'submitted')

            # This is not a lifecycle event, so it shouldn't display.
            create(:workflow_step,
                   druid:,
                   version: 2,
                   process: 'technical-metadata',
                   status: 'waiting')
          end

          it 'draws milestones from the current version' do
            expect(returned_milestone_versions).to eq ['2']
            expect(returned_milestone_text).to eq ['submitted']
          end
        end
      end

      context 'when active-only is not set' do
        let(:wf) do
          create(:workflow_step,
                 process: 'start-accession',
                 version: 1,
                 lane_id: 'default',
                 status: 'completed',
                 lifecycle: 'submitted')
        end

        before do
          create(:workflow_step,
                 druid:,
                 version: 2,
                 process: 'start-accession',
                 status: 'completed',
                 lifecycle: 'submitted')

          # This is not a lifecycle event, so it shouldn't display.
          create(:workflow_step,
                 druid:,
                 version: 2,
                 process: 'shelve',
                 lane_id: 'fast',
                 status: 'completed')

          # This is not a complete event, so it shouldn't display.
          create(:workflow_step,
                 druid:,
                 version: 2,
                 process: 'sdr-ingest-transfer',
                 status: 'waiting',
                 lifecycle: 'indexed')
        end

        it 'draws milestones from the all versions' do
          expect(returned_milestone_versions).to match_array %w[1 2]
          expect(returned_milestone_text).to match_array %w[submitted submitted]
        end
      end
    end
  end

  describe '#milestone?' do
    subject(:service) { described_class.new(druid: druid, version: 3, active_only: true) }

    before do
      allow(service).to receive(:lifecycle_xml).and_return(ng_xml) # rubocop:disable RSpec/SubjectStub
    end

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

  describe '#milestones' do
    subject(:milestones) { service.milestones }

    let(:service) { described_class.new(druid: druid) }

    let(:xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <lifecycle objectId="druid:gv054hp4128">
          <milestone date="2012-01-26T21:06:54-0800" version="2">published</milestone>
        </lifecycle>
      XML
    end

    before do
      allow(service).to receive(:lifecycle_xml).and_return(ng_xml)
    end

    it 'includes the version in with the milestones' do
      expect(milestones.first[:milestone]).to eq('published')
      expect(milestones.first[:version]).to eq('2')
    end
  end
end
