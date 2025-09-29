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
  let(:druid) { 'druid:xx999xx9999' }
  let(:trace_id) { 'abc123' }

  let(:releasable) do
    instance_double(Indexing::Indexers::ReleasableIndexer,
                    to_solr: { 'released_to_ssim' => %w[searchworks earthworks] })
  end
  let(:workflows) do
    instance_double(Indexing::Indexers::WorkflowsIndexer, to_solr: { 'wf_ssim' => ['accessionWF'] })
  end
  let(:admin_tags) do
    instance_double(Indexing::Indexers::AdministrativeTagIndexer, to_solr: { 'tag_ssim' => ['Test : Tag'] })
  end
  # rubocop:enable Style/StringHashKeys

  before do
    described_class.reset_parent_collections
    allow(Indexing::WorkflowFields).to receive(:for).and_return({ milestones_ssim: %w[foo bar] })
    allow(Indexing::Indexers::ReleasableIndexer).to receive(:new).and_return(releasable)
    allow(Indexing::Indexers::WorkflowsIndexer).to receive(:new).and_return(workflows)
    allow(Indexing::Indexers::AdministrativeTagIndexer).to receive(:new).and_return(admin_tags)
    allow(AdministrativeTags).to receive(:for).and_return([])
  end

  context 'when the model is an item' do
    let(:cocina) do
      build(:dro, id: druid).new(
        structural: {
          isMemberOf: collections
        }
      )
    end

    context 'without collections' do
      let(:collections) { [] }

      it { is_expected.to be_instance_of Indexing::Indexers::CompositeIndexer::Instance }
    end

    context 'with collections' do
      let(:related) { build(:collection) }
      let(:collections) { ['druid:bc999df2323'] }

      before do
        allow(CocinaObjectStore).to receive(:find).and_return(related)
      end

      it 'returns indexer' do
        expect(indexer).to be_instance_of Indexing::Indexers::CompositeIndexer::Instance
        expect(CocinaObjectStore).to have_received(:find).with(collections.first)
      end
    end

    context 'with a cached collections' do
      let(:related) { build(:collection) }
      let(:collections) { ['druid:bc999df2323'] }
      let(:item_tags) { [instance_double(Dor::ReleaseTag)] }

      before do
        allow(CocinaObjectStore).to receive(:find).and_return(related)
        allow(ReleaseTagService).to receive(:item_tags).and_return(item_tags)
        described_class.for(
          model: cocina_with_metadata,
          trace_id:
        )
      end

      it 'uses the cached collection' do
        expect(indexer).to be_instance_of Indexing::Indexers::CompositeIndexer::Instance
        expect(CocinaObjectStore).to have_received(:find).with(collections.first).once
        expect(ReleaseTagService).to have_received(:item_tags).with(cocina_object: related).once
      end
    end

    context "with collections that can't be resolved" do
      let(:collections) { ['druid:bc999df2323'] }

      before do
        allow(CocinaObjectStore).to receive(:find).and_raise(CocinaObjectStore::CocinaObjectNotFoundError)
      end

      it 'logs to honeybadger' do
        allow(Honeybadger).to receive(:notify).and_return('16ae4ff7-9449-43af-9988-77772858878c')
        expect(indexer).to be_instance_of Indexing::Indexers::CompositeIndexer::Instance

        # Ensure that errors are stripped out of parent_collections
        expect(Indexing::Indexers::AdministrativeTagIndexer).to have_received(:new)
          .with(cocina: Cocina::Models::DROWithMetadata,
                id: String,
                administrative_tags: [],
                parent_collections: [],
                parent_collections_release_tags: {},
                workflows: nil,
                release_tags: nil,
                milestones: nil,
                trace_id:)
        expect(Honeybadger).to have_received(:notify)
          .with('Bad association found on druid:xx999xx9999. druid:bc999df2323 could not be found').twice
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

  describe '#to_solr' do
    subject(:solr_doc) { indexer.to_solr }

    let(:apo_id) { 'druid:bd999bd9999' }
    let(:apo) { build(:admin_policy, id: apo_id) }

    before do
      allow(CocinaObjectStore).to receive(:find).and_return(apo)
    end

    context 'when the model is an item' do
      let(:cocina) do
        build(:dro, id: druid, admin_policy_id: apo_id).new(
          description: {
            title: [{ value: 'Test obj' }],
            purl: "https://purl.stanford.edu/#{druid.delete_prefix('druid:')}",
            subject: [{ type: 'topic', value: 'word' }],
            event: [
              {
                type: 'creation',
                date: [
                  {
                    value: '2021-01-01',
                    status: 'primary',
                    encoding: {
                      code: 'w3cdtf'
                    },
                    type: 'creation'
                  }
                ]
              },
              {
                type: 'publication',
                location: [
                  {
                    value: 'Moskva'
                  }
                ],
                contributor: [
                  {
                    name: [
                      {
                        value: 'Izdatelʹstvo "Vesʹ Mir"'
                      }
                    ],
                    type: 'organization',
                    role: [{ value: 'publisher' }]
                  }
                ]
              }
            ]
          }
        )
      end

      it 'has required fields' do
        expect(solr_doc).to include('milestones_ssim', 'wf_ssim', 'tag_ssim')

        expect(solr_doc['originInfo_date_created_tesim']).to eq '2021-01-01'
        expect(solr_doc['originInfo_publisher_tesim']).to eq 'Izdatelʹstvo "Vesʹ Mir"'
        expect(solr_doc['originInfo_place_placeTerm_tesim']).to eq 'Moskva'
      end
    end

    context 'when the model is an admin policy' do
      let(:model) { Dor::AdminPolicyObject.new(pid: druid) }
      let(:cocina) do
        build(:admin_policy, id: druid).new(
          administrative: {
            hasAdminPolicy: apo_id,
            hasAgreement: 'druid:bb033gt0615',
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it { is_expected.to include('milestones_ssim', 'wf_ssim', 'tag_ssim') }
    end

    context 'when the model is a hydrus apo' do
      let(:model) { Hydrus::AdminPolicyObject.new(pid: druid) }
      let(:cocina) do
        build(:admin_policy, id: druid).new(
          administrative: {
            hasAdminPolicy: apo_id,
            hasAgreement: 'druid:bb033gt0615',
            accessTemplate: { view: 'world', download: 'world' }
          }
        )
      end

      it { is_expected.to include('milestones_ssim', 'wf_ssim', 'tag_ssim') }
    end
  end
end
