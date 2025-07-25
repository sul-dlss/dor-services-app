# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::WorkflowFields do
  let(:doc) { described_class.for(druid:, version:) }
  let(:druid) { 'druid:ab123cd4567' }
  let(:version) { 4 }

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
      instance_double(described_class::Status,
                      milestones:,
                      display: 'v4 In accessioning (described, published)',
                      display_simplified: 'In accessioning')
    end

    before do
      allow(described_class::Status).to receive(:new).and_return(status)
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

  describe Indexing::WorkflowFields::Status do
    subject(:instance) do
      described_class.new(druid:, version: version)
    end

    let(:version) { '2' }

    before do
      allow_any_instance_of(WorkflowLifecycleService).to receive(:lifecycle_xml).and_return(Nokogiri::XML(xml)) # rubocop:disable RSpec/AnyInstance
    end

    describe '#display' do
      subject(:status) { instance.display }

      describe 'for gv054hp4128' do
        context 'when current version is published, but does not have a version attribute' do
          let(:xml) do
            '<?xml version="1.0" encoding="UTF-8"?>
          <lifecycle objectId="druid:gv054hp4128">
          <milestone date="2012-11-06T16:19:15-0800" version="2">described</milestone>
          <milestone date="2012-11-06T16:21:02-0800">opened</milestone>
          <milestone date="2012-11-06T16:30:03-0800">submitted</milestone>
          <milestone date="2012-11-06T16:35:00-0800">described</milestone>
          <milestone date="2012-11-06T16:59:39-0800" version="3">published</milestone>
          <milestone date="2012-11-06T16:59:39-0800">published</milestone>
          </lifecycle>'
          end

          let(:version) { '4' }

          it 'generates a status string' do
            expect(status).to eq('v4 In accessioning (published)')
          end
        end

        context 'when current version matches the attribute in the milestone' do
          let(:xml) do
            '<?xml version="1.0" encoding="UTF-8"?>
          <lifecycle objectId="druid:gv054hp4128">
          <milestone date="2012-11-06T16:19:15-0800" version="2">described</milestone>
          <milestone date="2012-11-06T16:59:39-0800" version="3">published</milestone>
          </lifecycle>'
          end
          let(:version) { '3' }

          it 'generates a status string' do
            expect(status).to eq('v3 In accessioning (published)')
          end
        end
      end

      describe 'for bd504dj1946' do
        let(:xml) do
          '<?xml version="1.0"?>
        <lifecycle objectId="druid:bd504dj1946">
        <milestone date="2013-04-03T15:01:57-0700">registered</milestone>
        <milestone date="2013-04-03T16:20:19-0700">digitized</milestone>
        <milestone date="2013-04-16T14:18:20-0700" version="1">submitted</milestone>
        <milestone date="2013-04-16T14:32:54-0700" version="1">described</milestone>
        <milestone date="2013-04-16T14:55:10-0700" version="1">published</milestone>
        <milestone date="2013-07-21T05:27:23-0700" version="1">deposited</milestone>
        <milestone date="2013-07-21T05:28:09-0700" version="1">accessioned</milestone>
        <milestone date="2013-08-15T11:59:16-0700" version="2">opened</milestone>
        <milestone date="2013-10-01T12:01:07-0700" version="2">submitted</milestone>
        <milestone date="2013-10-01T12:01:24-0700" version="2">described</milestone>
        <milestone date="2013-10-01T12:05:38-0700" version="2">published</milestone>
        <milestone date="2013-10-01T12:10:56-0700" version="2">deposited</milestone>
        <milestone date="2013-10-01T12:11:10-0700" version="2">accessioned</milestone>
        </lifecycle>'
        end

        it 'handles a v2 accessioned object' do
          expect(status).to eq('v2 Accessioned')
        end

        context 'when version is an integer' do
          let(:version) { 2 }

          it 'converts to a string' do
            expect(status).to eq('v2 Accessioned')
          end
        end

        context 'when there are no lifecycles for the current version, indicating malfunction in workflow' do
          let(:version) { '3' }

          it 'gives a status of unknown' do
            expect(status).to eq('v3 Unknown Status')
          end
        end

        context 'when time is requested' do
          subject(:status) { instance.display(include_time: true) }

          it 'includes a formatted date/time if one is requested' do
            expect(status).to eq('v2 Accessioned 2013-10-01 07:11PM')
          end
        end
      end

      context 'with an accessioned step with the exact same timestamp as the deposited step' do
        subject(:status) { instance.display(include_time: true) }

        let(:xml) do
          '<?xml version="1.0"?>
        <lifecycle objectId="druid:bd504dj1946">
        <milestone date="2013-04-03T15:01:57-0700">registered</milestone>
        <milestone date="2013-04-03T16:20:19-0700">digitized</milestone>
        <milestone date="2013-04-16T14:18:20-0700" version="1">submitted</milestone>
        <milestone date="2013-04-16T14:32:54-0700" version="1">described</milestone>
        <milestone date="2013-04-16T14:55:10-0700" version="1">published</milestone>
        <milestone date="2013-07-21T05:27:23-0700" version="1">deposited</milestone>
        <milestone date="2013-07-21T05:28:09-0700" version="1">accessioned</milestone>
        <milestone date="2013-08-15T11:59:16-0700" version="2">opened</milestone>
        <milestone date="2013-10-01T12:01:07-0700" version="2">submitted</milestone>
        <milestone date="2013-10-01T12:01:24-0700" version="2">described</milestone>
        <milestone date="2013-10-01T12:05:38-0700" version="2">published</milestone>
        <milestone date="2013-10-01T12:10:56-0700" version="2">deposited</milestone>
        <milestone date="2013-10-01T12:10:56-0700" version="2">accessioned</milestone>
        </lifecycle>'
        end

        it 'has the correct status of accessioned (v2) object' do
          expect(status).to eq('v2 Accessioned 2013-10-01 07:10PM')
        end
      end

      context 'with an accessioned step with an ealier timestamp than the deposited step' do
        subject(:status) { instance.display(include_time: true) }

        let(:xml) do
          '<?xml version="1.0"?>
        <lifecycle objectId="druid:bd504dj1946">
        <milestone date="2013-04-03T15:01:57-0700">registered</milestone>
        <milestone date="2013-04-03T16:20:19-0700">digitized</milestone>
        <milestone date="2013-04-16T14:18:20-0700" version="1">submitted</milestone>
        <milestone date="2013-04-16T14:32:54-0700" version="1">described</milestone>
        <milestone date="2013-04-16T14:55:10-0700" version="1">published</milestone>
        <milestone date="2013-07-21T05:27:23-0700" version="1">deposited</milestone>
        <milestone date="2013-07-21T05:28:09-0700" version="1">accessioned</milestone>
        <milestone date="2013-08-15T11:59:16-0700" version="2">opened</milestone>
        <milestone date="2013-10-01T12:01:07-0700" version="2">submitted</milestone>
        <milestone date="2013-10-01T12:01:24-0700" version="2">described</milestone>
        <milestone date="2013-10-01T12:05:38-0700" version="2">published</milestone>
        <milestone date="2013-10-01T12:10:56-0700" version="2">deposited</milestone>
        <milestone date="2013-09-01T12:10:56-0700" version="2">accessioned</milestone>
        </lifecycle>'
        end

        it 'has the correct status of accessioned (v2) object' do
          expect(status).to eq('v2 Accessioned 2013-09-01 07:10PM')
        end
      end

      context 'with a deposited step for a non-accessioned object' do
        subject(:status) { instance.display(include_time: true) }

        let(:xml) do
          '<?xml version="1.0"?>
        <lifecycle objectId="druid:bd504dj1946">
        <milestone date="2013-04-03T15:01:57-0700">registered</milestone>
        <milestone date="2013-04-03T16:20:19-0700">digitized</milestone>
        <milestone date="2013-04-16T14:18:20-0700" version="1">submitted</milestone>
        <milestone date="2013-04-16T14:32:54-0700" version="1">described</milestone>
        <milestone date="2013-04-16T14:55:10-0700" version="1">published</milestone>
        <milestone date="2013-07-21T05:27:23-0700" version="1">deposited</milestone>
        <milestone date="2013-07-21T05:28:09-0700" version="1">accessioned</milestone>
        <milestone date="2013-08-15T11:59:16-0700" version="2">opened</milestone>
        <milestone date="2013-10-01T12:01:07-0700" version="2">submitted</milestone>
        <milestone date="2013-10-01T12:01:24-0700" version="2">described</milestone>
        <milestone date="2013-10-01T12:05:38-0700" version="2">published</milestone>
        <milestone date="2013-10-01T12:10:56-0700" version="2">deposited</milestone>
        </lifecycle>'
        end

        it 'has the correct status of deposited (v2) object' do
          expect(status).to eq('v2 In accessioning (published, deposited) 2013-10-01 07:10PM')
        end
      end
    end

    describe '#display_simplified' do
      subject(:status) { instance.display_simplified }

      let(:xml) do
        '<?xml version="1.0" encoding="UTF-8"?>
      <lifecycle objectId="druid:gv054hp4128">
      <milestone date="2012-11-06T16:19:15-0800" version="2">described</milestone>
      <milestone date="2012-11-06T16:21:02-0800">opened</milestone>
      <milestone date="2012-11-06T16:30:03-0800">submitted</milestone>
      <milestone date="2012-11-06T16:35:00-0800">described</milestone>
      <milestone date="2012-11-06T16:59:39-0800" version="3">published</milestone>
      <milestone date="2012-11-06T16:59:39-0800">published</milestone>
      </lifecycle>'
      end

      it 'generates a status string' do
        expect(status).to eq('In accessioning')
      end
    end
  end
end
