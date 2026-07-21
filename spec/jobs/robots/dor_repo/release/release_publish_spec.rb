# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Release::ReleasePublish, type: :robot do
  subject(:perform) { test_perform(robot, druid, version: 4) }

  let(:druid) { 'bb222cc3333' }
  let!(:repository_object) { create(:repository_object, :closed, external_identifier: druid) }
  let(:cocina_object) { instance_double(Cocina::Models::DRO, dro?: true, access: dro_access, admin_policy?: false) }
  let(:dro_access) { instance_double(Cocina::Models::DROAccess, view: 'world') }
  let(:robot) { described_class.new }

  let(:release_tags) do
    [
      Dor::ReleaseTag.new(
        to: 'Searchworks',
        what: 'self',
        date: '2014-08-30T01:06:28.000+00:00',
        who: 'petucket',
        release: true
      ),
      Dor::ReleaseTag.new(
        to: 'Purl sitemap',
        what: 'self',
        date: '2014-08-30T01:06:28.000+00:00',
        who: 'petucket',
        release: true
      ),
      Dor::ReleaseTag.new(
        to: 'Earthworks',
        what: 'self',
        date: '2014-08-30T01:06:28.000+00:00',
        who: 'petucket',
        release: false
      )
    ]
  end

  before do
    allow(PublicMetadataReleaseTagService).to receive(:for_public_metadata)
      .with(cocina_object:).and_return(release_tags)
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_object)
    allow(PurlFetcher::Client::ReleaseTags).to receive(:release)
    allow(Workflow::LifecycleService).to receive(:milestone?).and_return(true)
  end

  context 'when the last closed version is published' do
    it 'calls purl fetcher with the release tags' do
      perform

      expect(Workflow::LifecycleService).to have_received(:milestone?)
        .with(druid:, milestone_name: 'published', version: repository_object.last_closed_version_version)
      expect(PurlFetcher::Client::ReleaseTags).to have_received(:release)
        .with(druid:, index: ['Searchworks', 'Purl sitemap'], delete: ['Earthworks'])
    end
  end

  context 'when an unpublished item' do
    before do
      allow(Workflow::LifecycleService).to receive(:milestone?).and_return(false)
    end

    it 'raises when the last closed version is not published' do
      expect { perform }.to raise_error(Robots::DorRepo::Release::ReleasePublish::PublishNotCompleteError)
    end
  end

  context 'when the object does not have a closed version' do
    let!(:repository_object) { create(:repository_object, external_identifier: druid) }

    it 'raises without checking for a published milestone' do
      expect { perform }.to raise_error(Robots::DorRepo::Release::ReleasePublish::PublishNotCompleteError)

      expect(Workflow::LifecycleService).not_to have_received(:milestone?)
    end
  end

  context 'when a dark DRO' do
    let(:dro_access) { instance_double(Cocina::Models::DROAccess, view: 'dark') }

    it 'skips publishing' do
      expect(perform).to have_attributes(status: 'skipped')

      expect(PurlFetcher::Client::ReleaseTags).not_to have_received(:release)
    end
  end

  context 'when a collection' do
    let(:cocina_object) { instance_double(Cocina::Models::Collection, dro?: false, admin_policy?: false, access: dro_access) }

    it 'calls purl fetcher with the release tags' do
      perform

      expect(PurlFetcher::Client::ReleaseTags).to have_received(:release)
        .with(druid:, index: ['Searchworks', 'Purl sitemap'], delete: ['Earthworks'])
    end
  end
end
