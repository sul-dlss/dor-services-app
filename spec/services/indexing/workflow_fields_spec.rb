# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::WorkflowFields do
  let(:doc) { described_class.for(druid:, version:, milestones:) }
  let(:druid) { 'druid:ab123cd4567' }
  let(:version) { 4 }
  let(:milestones) { [] }

  context 'with milestones' do
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
      expect(doc['processing_status_text_ssidv']).to eq 'In accessioning'
      expect(doc).to match a_hash_including('opened_dtpsimdv' => including('2012-11-07T00:21:02Z'))
      expect(doc['published_earliest_dtpsidv']).to eq('2012-01-27T05:06:54Z')
      expect(doc['published_latest_dtpsidv']).to eq('2012-11-07T00:59:39Z')
      expect(doc['published_dtpsimdv'].first).to eq(doc['published_earliest_dtpsidv'])
      expect(doc['published_dtpsimdv'].last).to eq(doc['published_latest_dtpsidv'])
      expect(doc['published_dtpsimdv'].size).to eq(3) # not 4 because 1 deduplicated value removed!
      expect(doc['opened_earliest_dtpsidv']).to eq('2012-10-29T23:30:07Z') #  2012-10-29T16:30:07-0700
      expect(doc['opened_latest_dtpsidv']).to eq('2012-11-07T00:21:02Z') #  2012-11-06T16:21:02-0800
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
      described_class.new(druid:, version: version, milestones:)
    end

    let(:version) { '2' }

    describe '#display' do
      subject(:status) { instance.display }

      describe 'for gv054hp4128' do
        context 'when current version is published, but does not have a version attribute' do
          let(:milestones) do
            [
              { milestone: 'described', at: DateTime.parse('2012-11-06 16:19:15 -0800'), version: '2' },
              { milestone: 'opened', at: DateTime.parse('2012-11-06 16:21:02 -0800'), version: nil },
              { milestone: 'submitted', at: DateTime.parse('2012-11-06 16:30:03 -0800'), version: nil },
              { milestone: 'described', at: DateTime.parse('2012-11-06 16:35:00 -0800'), version: nil },
              { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: '3' },
              { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: nil }
            ]
          end

          let(:version) { '4' }

          it 'generates a status string' do
            expect(status).to eq('v4 In accessioning (published)')
          end
        end

        context 'when current version matches the attribute in the milestone' do
          let(:milestones) do
            [
              { milestone: 'described', at: DateTime.parse('2012-11-06 16:19:15 -0800'), version: '2' },
              { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: '3' }
            ]
          end

          let(:version) { '3' }

          it 'generates a status string' do
            expect(status).to eq('v3 In accessioning (published)')
          end
        end
      end

      describe 'for bd504dj1946' do
        let(:milestones) do
          [
            { milestone: 'registered', at: DateTime.parse('2013-04-03 15:01:57 -0700'), version: nil },
            { milestone: 'digitized', at: DateTime.parse('2013-04-03 16:20:19 -0700'), version: nil },
            { milestone: 'submitted', at: DateTime.parse('2013-04-16 14:18:20 -0700'), version: '1' },
            { milestone: 'described', at: DateTime.parse('2013-04-16 14:32:54 -0700'), version: '1' },
            { milestone: 'published', at: DateTime.parse('2013-04-16 14:55:10 -0700'), version: '1' },
            { milestone: 'deposited', at: DateTime.parse('2013-07-21 05:27:23 -0700'), version: '1' },
            { milestone: 'accessioned', at: DateTime.parse('2013-07-21 05:28:09 -0700'), version: '1' },
            { milestone: 'opened', at: DateTime.parse('2013-08-15 11:59:16 -0700'), version: '2' },
            { milestone: 'submitted', at: DateTime.parse('2013-10-01 12:01:07 -0700'), version: '2' },
            { milestone: 'described', at: DateTime.parse('2013-10-01 12:01:24 -0700'), version: '2' },
            { milestone: 'published', at: DateTime.parse('2013-10-01 12:05:38 -0700'), version: '2' },
            { milestone: 'deposited', at: DateTime.parse('2013-10-01 12:10:56 -0700'), version: '2' },
            { milestone: 'accessioned', at: DateTime.parse('2013-10-01 12:11:10 -0700'), version: '2' }
          ]
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

        let(:milestones) do
          [
            { milestone: 'registered', at: DateTime.parse('2013-04-03 15:01:57 -0700'), version: nil },
            { milestone: 'digitized', at: DateTime.parse('2013-04-03 16:20:19 -0700'), version: nil },
            { milestone: 'submitted', at: DateTime.parse('2013-04-16 14:18:20 -0700'), version: '1' },
            { milestone: 'described', at: DateTime.parse('2013-04-16 14:32:54 -0700'), version: '1' },
            { milestone: 'published', at: DateTime.parse('2013-04-16 14:55:10 -0700'), version: '1' },
            { milestone: 'deposited', at: DateTime.parse('2013-07-21 05:27:23 -0700'), version: '1' },
            { milestone: 'accessioned', at: DateTime.parse('2013-07-21 05:28:09 -0700'), version: '1' },
            { milestone: 'opened', at: DateTime.parse('2013-08-15 11:59:16 -0700'), version: '2' },
            { milestone: 'submitted', at: DateTime.parse('2013-10-01 12:01:07 -0700'), version: '2' },
            { milestone: 'described', at: DateTime.parse('2013-10-01 12:01:24 -0700'), version: '2' },
            { milestone: 'published', at: DateTime.parse('2013-10-01 12:05:38 -0700'), version: '2' },
            { milestone: 'deposited', at: DateTime.parse('2013-10-01 12:10:56 -0700'), version: '2' },
            { milestone: 'accessioned', at: DateTime.parse('2013-10-01 12:10:56 -0700'), version: '2' }
          ]
        end

        it 'has the correct status of accessioned (v2) object' do
          expect(status).to eq('v2 Accessioned 2013-10-01 07:10PM')
        end
      end

      context 'with an accessioned step with an ealier timestamp than the deposited step' do
        subject(:status) { instance.display(include_time: true) }

        let(:milestones) do
          [
            { milestone: 'registered', at: DateTime.parse('2013-04-03 15:01:57 -0700'), version: nil },
            { milestone: 'digitized', at: DateTime.parse('2013-04-03 16:20:19 -0700'), version: nil },
            { milestone: 'submitted', at: DateTime.parse('2013-04-16 14:18:20 -0700'), version: '1' },
            { milestone: 'described', at: DateTime.parse('2013-04-16 14:32:54 -0700'), version: '1' },
            { milestone: 'published', at: DateTime.parse('2013-04-16 14:55:10 -0700'), version: '1' },
            { milestone: 'deposited', at: DateTime.parse('2013-07-21 05:27:23 -0700'), version: '1' },
            { milestone: 'accessioned', at: DateTime.parse('2013-07-21 05:28:09 -0700'), version: '1' },
            { milestone: 'opened', at: DateTime.parse('2013-08-15 11:59:16 -0700'), version: '2' },
            { milestone: 'submitted', at: DateTime.parse('2013-10-01 12:01:07 -0700'), version: '2' },
            { milestone: 'described', at: DateTime.parse('2013-10-01 12:01:24 -0700'), version: '2' },
            { milestone: 'published', at: DateTime.parse('2013-10-01 12:05:38 -0700'), version: '2' },
            { milestone: 'deposited', at: DateTime.parse('2013-10-01 12:10:56 -0700'), version: '2' },
            { milestone: 'accessioned', at: DateTime.parse('2013-09-01 12:10:56 -0700'), version: '2' }
          ]
        end

        it 'has the correct status of accessioned (v2) object' do
          expect(status).to eq('v2 Accessioned 2013-09-01 07:10PM')
        end
      end

      context 'with a deposited step for a non-accessioned object' do
        subject(:status) { instance.display(include_time: true) }

        let(:milestones) do
          [
            { milestone: 'registered', at: DateTime.parse('2013-04-03 15:01:57 -0700'), version: nil },
            { milestone: 'digitized', at: DateTime.parse('2013-04-03 16:20:19 -0700'), version: nil },
            { milestone: 'submitted', at: DateTime.parse('2013-04-16 14:18:20 -0700'), version: '1' },
            { milestone: 'described', at: DateTime.parse('2013-04-16 14:32:54 -0700'), version: '1' },
            { milestone: 'published', at: DateTime.parse('2013-04-16 14:55:10 -0700'), version: '1' },
            { milestone: 'deposited', at: DateTime.parse('2013-07-21 05:27:23 -0700'), version: '1' },
            { milestone: 'accessioned', at: DateTime.parse('2013-07-21 05:28:09 -0700'), version: '1' },
            { milestone: 'opened', at: DateTime.parse('2013-08-15 11:59:16 -0700'), version: '2' },
            { milestone: 'submitted', at: DateTime.parse('2013-10-01 12:01:07 -0700'), version: '2' },
            { milestone: 'described', at: DateTime.parse('2013-10-01 12:01:24 -0700'), version: '2' },
            { milestone: 'published', at: DateTime.parse('2013-10-01 12:05:38 -0700'), version: '2' },
            { milestone: 'deposited', at: DateTime.parse('2013-10-01 12:10:56 -0700'), version: '2' }
          ]
        end

        it 'has the correct status of deposited (v2) object' do
          expect(status).to eq('v2 In accessioning (published, deposited) 2013-10-01 07:10PM')
        end
      end
    end

    describe '#display_simplified' do
      subject(:status) { instance.display_simplified }

      let(:milestones) do
        [
          { milestone: 'described', at: DateTime.parse('2012-11-06 16:19:15 -0800'), version: '2' },
          { milestone: 'opened', at: DateTime.parse('2012-11-06 16:21:02 -0800'), version: nil },
          { milestone: 'submitted', at: DateTime.parse('2012-11-06 16:30:03 -0800'), version: nil },
          { milestone: 'described', at: DateTime.parse('2012-11-06 16:35:00 -0800'), version: nil },
          { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: '3' },
          { milestone: 'published', at: DateTime.parse('2012-11-06 16:59:39 -0800'), version: nil }
        ]
      end

      it 'generates a status string' do
        expect(status).to eq('In accessioning')
      end
    end
  end
end
