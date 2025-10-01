# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Builders::DocumentBuilder do
  subject(:indexer) do
    described_class.for(model: cocina_with_metadata, trace_id:)
  end

  let(:cocina_with_metadata) do
    Cocina::Models.with_metadata(cocina, 'unknown_lock', created: DateTime.parse('Wed, 01 Jan 2020 12:00:01 GMT'),
                                                         modified: DateTime.parse('Thu, 04 Mar 2021 23:05:34 GMT'))
  end
  let(:cocina) do
    build(:dro, id: druid).new(
      structural: {
        isMemberOf: collections
      }
    )
  end
  let(:collections) { [] }
  let(:druid) { 'druid:xx999xx9999' }
  let(:collection_druid) { 'druid:bc999df2323' }
  let(:trace_id) { 'abc123' }

  context 'when the model is an item' do
    it { is_expected.to be_instance_of Indexing::Indexers::CompositeIndexer::Instance }

    context "with collections that can't be resolved" do
      let(:collections) { [collection_druid] }

      before do
        allow(CocinaObjectStore).to receive(:find).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
        allow(Indexing::Indexers::CompositeIndexer::Instance).to receive(:new).and_call_original
      end

      it 'logs to honeybadger' do
        allow(Honeybadger).to receive(:notify).and_return('16ae4ff7-9449-43af-9988-77772858878c')
        expect(indexer).to be_instance_of Indexing::Indexers::CompositeIndexer::Instance

        # Ensure that errors are stripped out of parent_collections
        expect(Indexing::Indexers::CompositeIndexer::Instance).to have_received(:new)
          .with(
            Array, # This is the array of indexers
            a_hash_including(
              parent_collections: []
            )
          )
        expect(Honeybadger).to have_received(:notify)
          .with('Bad association found on druid:xx999xx9999. druid:bc999df2323 could not be found')
      end
    end

    context 'when an exception is raised' do
      let(:collections) { [] }
      let(:error_message) { 'nil is not a symbol nor a string' }

      before do
        allow(Honeybadger).to receive(:notify)
        allow(Cocina::Models::Mapping::ToMods::Description).to receive(:transform).and_raise(TypeError, error_message)
      end

      it 'logs a data error to honeybadger' do
        expect { indexer }.to raise_error(TypeError, error_message)

        expect(Honeybadger).to have_received(:notify).once.with(/Unexpected indexing exception/,
                                                                hash_including(:backtrace, :context, :error_message,
                                                                               :tags))
      end
    end
  end

  context 'when the model is an admin policy' do
    let(:cocina) { build(:admin_policy) }

    it { is_expected.to be_instance_of Indexing::Indexers::CompositeIndexer::Instance }
  end

  context 'when the model is a collection' do
    let(:cocina) { build(:collection) }

    it { is_expected.to be_instance_of Indexing::Indexers::CompositeIndexer::Instance }
  end

  context 'when the model is an agreement' do
    let(:cocina) { build(:dro, type: Cocina::Models::ObjectType.agreement) }

    it { is_expected.to be_instance_of Indexing::Indexers::CompositeIndexer::Instance }
  end

  describe 'parameters' do
    let(:administrative_tags) { ['tag1', 'tag2'] }
    let!(:parent_collection_repository_object) do
      create(:repository_object, :collection, :with_repository_object_version, external_identifier: collection_druid)
    end
    let(:parent_collections) { [parent_collection_repository_object.to_cocina_with_metadata] }
    let(:collections) { [collection_druid] }
    let(:milestones) { [{ milestone: 'accessioned' }] }
    let(:release_tags) { [instance_double(Dor::ReleaseTag)] }
    let(:parent_collection_release_tags) { [instance_double(Dor::ReleaseTag)] }
    let(:parent_collections_release_tags) { { collection_druid => parent_collection_release_tags } }
    let(:workflows) { [instance_double(Workflow::WorkflowResponse)] }

    before do
      allow(Indexing::Indexers::CompositeIndexer::Instance).to receive(:new).and_call_original
      allow(AdministrativeTags).to receive(:for).with(identifier: druid).and_return(administrative_tags)
    end

    context 'when optional parameters are provided' do
      it 'uses the provided values' do
        described_class.for(model: cocina_with_metadata, trace_id:, parent_collections:,
                            milestones:, parent_collections_release_tags:, release_tags:, workflows:)
        expect(Indexing::Indexers::CompositeIndexer::Instance).to have_received(:new)
          .with(
            Array, # This is the array of indexers
            {
              cocina: cocina_with_metadata,
              id: druid,
              administrative_tags: administrative_tags,
              parent_collections:,
              milestones:,
              parent_collections_release_tags: { 'druid:bc999df2323' => parent_collection_release_tags },
              release_tags:,
              workflows:,
              trace_id:
            }
          )
      end
    end

    context 'when optional parameters are not provided' do
      before do
        allow(Workflow::LifecycleService).to receive(:milestones).with(druid:).and_return(milestones)
        allow(ReleaseTagService).to receive(:tags).with(druid:).and_return(release_tags)
        allow(ReleaseTagService).to receive(:tags).with(druid: collection_druid)
                                                  .and_return(parent_collection_release_tags)
        allow(Workflow::Service).to receive(:workflows).with(druid:).and_return(workflows)
      end

      it 'fetches them as needed' do
        indexer
        expect(Indexing::Indexers::CompositeIndexer::Instance).to have_received(:new)
          .with(
            Array, # This is the array of indexers
            {
              cocina: cocina_with_metadata,
              id: druid,
              administrative_tags: administrative_tags,
              parent_collections:,
              milestones:,
              parent_collections_release_tags:,
              release_tags:,
              workflows:,
              trace_id:
            }
          )
      end
    end
  end
end
