# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Robots::DorRepo::Release::ReleaseMembers, type: :robot do
  subject(:perform) { test_perform(robot, druid) }

  let(:robot) { described_class.new }
  let(:druid) { 'druid:bb222cc3333' }

  let(:release_tags) { [] }
  let(:publish_item) { instance_double(Publish::Item, published?: true) }

  before do
    allow(ReleaseTagService).to receive(:tags).with(druid:).and_return(release_tags)
    allow(CocinaObjectStore).to receive(:find).with(druid).and_return(cocina_model)
    allow(Publish::Item).to receive(:new).and_return(publish_item)
  end

  context 'when the model is an item' do
    let(:cocina_model) { instance_double(Cocina::Models::DRO, collection?: false) }

    it 'does nothing' do
      perform

      expect(ReleaseTagService).not_to have_received(:tags)
    end
  end

  context 'when the model is an apo' do
    let(:cocina_model) { instance_double(Cocina::Models::AdminPolicy, collection?: false) }

    it 'does nothing' do
      perform

      expect(ReleaseTagService).not_to have_received(:tags)
    end
  end

  context 'when the model is a collection' do
    let(:release_tags) { [] }

    let(:cocina_model) do
      build(:collection, id: 'druid:bc123df4567').new(
        administrative: {
          hasAdminPolicy: 'druid:xx999xx9999'
        }
      )
    end

    context 'when the collection is released to self only' do
      let(:release_tag) { Dor::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') }
      let(:release_tags) { [release_tag] }

      before do
        allow(RepositoryObject).to receive(:currently_members_of_collection)
      end

      it 'does not add workflow for item members' do
        perform

        expect(RepositoryObject).not_to have_received(:currently_members_of_collection)
      end
    end

    context 'when there are multiple targets but they are all released to self only' do
      let(:release_tag1) { Dor::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') }
      let(:release_tag2) { Dor::ReleaseTag.new(to: 'Earthworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'petucket') }
      let(:release_tags) { [release_tag1, release_tag2] }

      before do
        allow(RepositoryObject).to receive(:currently_members_of_collection)
      end

      it 'does not add workflow for item members' do
        perform

        expect(RepositoryObject).not_to have_received(:currently_members_of_collection)
      end
    end

    context 'with multiple tags for a single target' do
      let(:release_tag1) { Dor::ReleaseTag.new(to: 'Searchworks', release: true, what: 'self', date: '2019-03-09 19:34:43 UTC', who: 'hfrost ') }
      let(:release_tag2) { Dor::ReleaseTag.new(to: 'Searchworks', release: false, what: 'self', date: '2020-02-07 19:34:43 UTC', who: 'jkalchik') }
      let(:release_tags) { [release_tag1, release_tag2] }

      before do
        allow(RepositoryObject).to receive(:currently_members_of_collection)
      end

      it 'does not add workflow for item members' do
        perform
        expect(RepositoryObject).not_to have_received(:currently_members_of_collection)
      end
    end

    context 'when the collection is not released to self' do
      let(:release_tag) { Dor::ReleaseTag.new(to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') }
      let(:release_tags) { [release_tag] }
      let(:members) do
        [
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb001zc5754', version: 1),
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb023nj3137', version: 2),
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb027yn4436', version: 1),
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb048rn5648', version: 1)
        ]
      end

      before do
        allow(RepositoryObject).to receive(:currently_members_of_collection).with(druid).and_return(members)
        allow(publish_item).to receive(:published?).and_return(true, true, true, false)
        allow(Workflow::Service).to receive(:create)
      end

      it 'runs for a collection and creates releaseWFs' do
        perform

        expect(Workflow::Service).to have_received(:create).exactly(3).times
        expect(Workflow::Service).to have_received(:create)
          .with(druid: 'druid:bb001zc5754', version: 1, workflow_name: 'releaseWF', lane_id: nil)
      end
    end

    context 'when there are multiple targets and at least one of the release targets is not released to self' do
      let(:release_tag1) { Dor::ReleaseTag.new(to: 'Searchworks', release: true, what: 'collection', date: '2016-10-07 19:34:43 UTC', who: 'lmcrae') }
      let(:release_tag2) { Dor::ReleaseTag.new(to: 'Earthworks', release: true, what: 'self', date: '2016-10-07 19:34:43 UTC', who: 'petucket') }
      let(:release_tags) { [release_tag1, release_tag2] }

      let(:members) do
        [
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb001zc5754', version: 1),
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb023nj3137', version: 2),
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb027yn4436', version: 1),
          instance_double(RepositoryObjectVersion, external_identifier: 'druid:bb048rn5648', version: 1)
        ]
      end

      before do
        allow(RepositoryObject).to receive(:currently_members_of_collection).with(druid).and_return(members)
        allow(publish_item).to receive(:published?).and_return(true, true, true, false)
        allow(Workflow::Service).to receive(:create)
      end

      it 'runs for a collection and creates releaseWFs' do
        perform

        expect(Workflow::Service).to have_received(:create).exactly(3).times
        expect(Workflow::Service).to have_received(:create)
          .with(druid: 'druid:bb001zc5754', version: 1, workflow_name: 'releaseWF', lane_id: nil)
      end
    end
  end
end
