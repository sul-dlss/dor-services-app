# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::WorkflowFields do
  let(:doc) { described_class.for(druid: 'druid:ab123cd4567', version: 4) }

  context 'with milestones' do
    let(:dsxml) do
      '
    <versionMetadata objectId="druid:ab123cd4567">
    <version versionId="1" tag="1.0.0">
    <description>Initial version</description>
    </version>
    <version versionId="2" tag="2.0.0">
    <description>Replacing main PDF</description>
    </version>
    <version versionId="3" tag="2.1.0">
    <description>Fixed title typo</description>
    </version>
    <version versionId="4" tag="2.2.0">
    <description>Another typo</description>
    </version>
    </versionMetadata>
    '
    end

    let(:milestones) do
      [
        { milestone: 'published', at: DateTime.parse('2012-01-26 21:06:54 -0800'), version: '2' },
        { milestone: 'opened', at: DateTime.parse('2012-10-29 16:30:07 -0700'), version: '2' },
        { milestone: 'submitted', at: DateTime.parse('2012-11-06 16:18:24 -0800'), version: '2' },
        { milestone: 'published', at: DateTime.parse('2012-11-06 16:19:07 -0800'), version: '2' },
        { milestone: 'accessioned', at: DateTime.parse('2012-11-06 16:19:10 -0800'), version: '2' },
        { milestone: 'described', at: DateTime.parse('2012-11-06 16:19:15 -0800'), version: '2' },
        { milestone: 'opened', at: DateTime.parse('2012-11-06 16:21:02 -0800'), version: nil },
        { milestone: 'submitted', at: DateTime.parse('2012-11-06 16:30:03 -0800'), version: nil },
        { milestone: 'described', at: DateTime.parse('2012-11-06 16:35:00 -0800'), version: nil },
        { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: '3' },
        { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: nil }
      ]
    end

    let(:status) do
      instance_double(Dor::Workflow::Client::Status,
                      milestones:,
                      display: 'v4 In accessioning (described, published)',
                      display_simplified: 'In accessioning')
    end

    let(:workflow_client) { instance_double(Dor::Workflow::Client, status:) }

    before do
      allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    end

    it 'includes the semicolon delimited version, an earliest published date and a status' do
      # published date should be the first published date
      expect(doc['status_ssi']).to eq 'v4 In accessioning (described, published)'
      expect(doc['processing_status_text_ssi']).to eq 'In accessioning'
      expect(doc).to match a_hash_including('opened_dttsim' => including('2012-11-07T00:21:02Z'))
      expect(doc['published_earliest_dttsi']).to eq('2012-01-27T05:06:54Z')
      expect(doc['published_latest_dttsi']).to eq('2012-11-07T00:59:39Z')
      expect(doc['published_dttsim'].first).to eq(doc['published_earliest_dttsi'])
      expect(doc['published_dttsim'].last).to eq(doc['published_latest_dttsi'])
      expect(doc['published_dttsim'].size).to eq(3) # not 4 because 1 deduplicated value removed!
      expect(doc['opened_earliest_dttsi']).to eq('2012-10-29T23:30:07Z') #  2012-10-29T16:30:07-0700
      expect(doc['opened_latest_dttsi']).to eq('2012-11-07T00:21:02Z') #  2012-11-06T16:21:02-0800
    end

    context 'when a new version has not been opened' do
      let(:milestones) do
        [{ milestone: 'submitted', at: DateTime.parse('2012-11-06 16:30:03 -0800'), version: nil },
         { milestone: 'described', at: DateTime.parse('2012-11-06 16:35:00 -0800'), version: nil },
         { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: '3' },
         { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: nil }]
      end

      it 'skips the versioning related steps if a new version has not been opened' do
        expect(doc['opened_dttsim']).to be_nil
      end
    end
  end
end
