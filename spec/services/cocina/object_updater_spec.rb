# frozen_string_literal: true

require 'rails_helper'

# Tests whether partial updates are handled correctly.
# It does not test the updates themselves.
RSpec.describe Cocina::ObjectUpdater do
  include Dry::Monads[:result]

  subject(:update) { described_class.run(item, cocina_object, event_factory: event_factory, trial: trial) }

  # For the existing item.
  let(:orig_cocina_object) do
    Cocina::Models.build(orig_cocina_attrs.with_indifferent_access)
  end

  # For the submitted item.
  let(:cocina_object) do
    Cocina::Models.build(cocina_attrs.with_indifferent_access)
  end

  let(:cocina_attrs) { orig_cocina_attrs }

  let(:event_factory) { class_double(EventFactory) }

  let(:trial) { false }

  before do
    allow(Cocina::Mapper).to receive(:build).and_return(orig_cocina_object)
    allow(Cocina::ApoExistenceValidator).to receive(:new).and_return(instance_double(Cocina::ApoExistenceValidator, valid?: true))
    allow(Settings.enabled_features).to receive(:update_descriptive).and_return(true)
    allow(AdministrativeTags).to receive(:for).and_return([])
    allow(event_factory).to receive(:create)
  end

  context 'when an admin policy' do
    let(:item) do
      instance_double(Dor::AdminPolicyObject, pid: 'druid:bc123df4567',
                                              save!: nil,
                                              administrativeMetadata: double,
                                              descMetadata: desc_metadata)
    end

    let(:desc_metadata) { double }

    let(:orig_cocina_attrs) do
      {
        type: 'http://cocina.sul.stanford.edu/models/admin_policy.jsonld',
        externalIdentifier: 'druid:bc123df4567',
        label: 'orig label',
        version: 1,
        administrative: { hasAdminPolicy: 'druid:dd999df4567' },
        description: { title: [{ value: 'orig title' }] }
      }
    end

    context 'when updating label' do
      before do
        allow(item).to receive(:label=)
        allow(Cocina::ToFedora::Identity).to receive(:apply_label)
      end

      context 'when label has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:label] = 'new label'
          end
        end

        it 'updates label' do
          update
          expect(item).to have_received(:label=).with('new label')
          expect(Cocina::ToFedora::Identity).to have_received(:apply_label)
        end
      end

      context 'when label has not changed' do
        it 'does not update label' do
          update
          expect(item).not_to have_received(:label=)
          expect(Cocina::ToFedora::Identity).not_to have_received(:apply_label)
        end
      end
    end

    context 'when updating description' do
      before do
        allow(desc_metadata).to receive(:content=)
        allow(desc_metadata).to receive(:content_will_change!)
        allow(Cocina::ToFedora::Descriptive).to receive(:transform).and_return(Nokogiri::XML::Builder.new)
        allow(Cocina::DescriptionRoundtripValidator).to receive(:valid_from_cocina?).and_return(Success())
      end

      context 'when description has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:description] = { title: [{ value: 'new title' }] }
          end
        end

        it 'updates description' do
          update
          expect(desc_metadata).to have_received(:content=)
          expect(desc_metadata).to have_received(:content_will_change!)
          expect(Cocina::ToFedora::Descriptive).to have_received(:transform)
        end
      end

      context 'when description has not changed' do
        it 'does not update descriptive' do
          update
          expect(desc_metadata).not_to have_received(:content=)
          expect(desc_metadata).not_to have_received(:content_will_change!)
          expect(Cocina::ToFedora::Descriptive).not_to have_received(:transform)
        end
      end
    end

    context 'when updating administrative' do
      before do
        allow(item).to receive(:admin_policy_object_id=)
        allow(item).to receive(:agreement_object_id=)
        allow(Cocina::ToFedora::AdministrativeMetadata).to receive(:write)
        allow(Cocina::ToFedora::Roles).to receive(:write)
      end

      context 'when administrative has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:administrative][:disseminationWorkflow] = 'assemblyWF'
          end
        end

        it 'updates administrative' do
          update
          expect(item).to have_received(:admin_policy_object_id=).with('druid:dd999df4567')
          expect(item).to have_received(:agreement_object_id=).with(nil) # nil is legitimate
          expect(Cocina::ToFedora::AdministrativeMetadata).to have_received(:write)
          expect(Cocina::ToFedora::Roles).to have_received(:write)
        end
      end

      context 'when administrative has not changed' do
        it 'does not update administrative' do
          update
          expect(item).not_to have_received(:admin_policy_object_id=)
          expect(Cocina::ToFedora::AdministrativeMetadata).not_to have_received(:write)
          expect(Cocina::ToFedora::Roles).not_to have_received(:write)
        end
      end
    end
  end

  context 'when a collection' do
    let(:item) do
      Dor::Collection.new(pid: 'druid:bc123df4567')
    end

    let(:orig_cocina_attrs) do
      {
        type: 'http://cocina.sul.stanford.edu/models/collection.jsonld',
        externalIdentifier: 'druid:bc123df4567',
        label: 'orig label',
        version: 1,
        access: { access: 'world' }
      }
    end

    before do
      allow(item).to receive(:save!)
    end

    context 'when updating label' do
      before do
        allow(item).to receive(:label=)
      end

      context 'when label has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:label] = 'new label'
          end
        end

        it 'updates label' do
          update
          expect(item).to have_received(:label=).with('new label')
          expect(item.objectLabel).to eq ['new label']
        end
      end

      context 'when label has not changed' do
        it 'does not update label' do
          update
          expect(item).not_to have_received(:label=)
          expect(item.objectLabel).to eq []
        end
      end
    end

    context 'when updating description' do
      let(:builder) do
        Nokogiri::XML::Builder.new do |b|
          b.test 'hello'
        end
      end

      before do
        allow(Cocina::ToFedora::Descriptive).to receive(:transform).and_return(builder)
        allow(Cocina::DescriptionRoundtripValidator).to receive(:valid_from_cocina?).and_return(Success())
      end

      context 'when description has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:description] = { title: [{ value: 'new title' }] }
          end
        end

        it 'updates description' do
          update
          expect(item.descMetadata.content).to eq '<test>hello</test>'
          expect(item.descMetadata).to be_content_changed
        end
      end

      context 'when description has not changed' do
        it 'does not update descriptive' do
          update
          expect(item.descMetadata.content).to be_nil
          expect(item.descMetadata).not_to be_content_changed
        end
      end
    end

    context 'when updating administrative' do
      before do
        allow(item).to receive(:admin_policy_object_id=)
      end

      context 'when administrative has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:administrative] = { hasAdminPolicy: 'druid:dd999df4567' }
          end
        end

        it 'updates administrative' do
          update
          expect(item).to have_received(:admin_policy_object_id=).with('druid:dd999df4567')
        end
      end

      context 'when administrative has not changed' do
        it 'does not update administrative' do
          update
          expect(item).not_to have_received(:admin_policy_object_id=)
        end
      end
    end

    context 'when updating access' do
      before do
        allow(Cocina::ToFedora::CollectionAccess).to receive(:apply)
      end

      context 'when access has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:access] = {
              access: 'dark'
            }
          end
        end

        it 'updates access' do
          update
          expect(Cocina::ToFedora::CollectionAccess).to have_received(:apply)
        end
      end

      context 'when access has not changed' do
        it 'does not update access' do
          update
          expect(Cocina::ToFedora::CollectionAccess).not_to have_received(:apply)
        end
      end
    end
  end

  context 'when a DRO' do
    let(:item) do
      instance_double(Dor::Item, pid: 'druid:bc123df4567',
                                 save!: nil,
                                 label: 'orig label',
                                 contentMetadata: content_metadata,
                                 descMetadata: desc_metadata,
                                 identityMetadata: identity_metadata)
    end

    let(:content_metadata) { double }

    let(:content_metadata_ng_xml) { double }

    let(:book_data_node) { double }

    let(:desc_metadata) { double }

    let(:identity_metadata) { double }

    let(:orig_cocina_attrs) do
      {
        type: 'http://cocina.sul.stanford.edu/models/media.jsonld',
        externalIdentifier: 'druid:bc123df4567',
        label: 'orig label',
        version: 1,
        access: {},
        administrative: { hasAdminPolicy: 'druid:dd999df4567' }
      }
    end

    context 'when updating label' do
      let(:cocina_attrs) do
        orig_cocina_attrs.tap do |attrs|
          attrs[:label] = 'new label'
        end
      end

      before do
        allow(item).to receive(:label=)
        allow(Cocina::ToFedora::Identity).to receive(:apply_label)
      end

      it 'updates label' do
        update
        expect(item).to have_received(:label=).with('new label')
        expect(Cocina::ToFedora::Identity).to have_received(:apply_label)
      end
    end

    context 'when updating description' do
      before do
        allow(desc_metadata).to receive(:content=)
        allow(desc_metadata).to receive(:content_will_change!)
        allow(Cocina::ToFedora::Descriptive).to receive(:transform).and_return(Nokogiri::XML::Builder.new)
        allow(Cocina::DescriptionRoundtripValidator).to receive(:valid_from_cocina?).and_return(Success())
      end

      context 'when description has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:description] = { title: [{ value: 'new title' }] }
          end
        end

        it 'updates description' do
          update
          expect(desc_metadata).to have_received(:content=)
          expect(desc_metadata).to have_received(:content_will_change!)
          expect(Cocina::ToFedora::Descriptive).to have_received(:transform)
        end
      end

      context 'when description has not changed' do
        it 'does not update descriptive' do
          update
          expect(desc_metadata).not_to have_received(:content=)
          expect(desc_metadata).not_to have_received(:content_will_change!)
          expect(Cocina::ToFedora::Descriptive).not_to have_received(:transform)
        end
      end
    end

    context 'when updating administrative' do
      before do
        allow(item).to receive(:admin_policy_object_id=)
        allow(AdministrativeTags).to receive(:create)
      end

      context 'when administrative has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:administrative] = {
              hasAdminPolicy: 'druid:ff000df4567',
              partOfProject: 'Google Books'
            }
          end
        end

        context 'when creating a new project tag' do
          it 'updates administrative' do
            update
            expect(item).to have_received(:admin_policy_object_id=).with('druid:ff000df4567')
            expect(AdministrativeTags).to have_received(:create)
          end
        end

        context 'when multiple project tags already exists' do
          before do
            allow(AdministrativeTags).to receive(:for).and_return(['Project : Phoenix', 'Project : Google Books'])
          end

          it 'updates administrative' do
            expect { update }.to raise_error(/Too many tags for prefix/)
          end
        end

        context 'when creating a new project tag with an existing project subtag' do
          before do
            allow(AdministrativeTags).to receive(:for).and_return(['Project : Google Books : Special'])
          end

          it 'updates administrative' do
            update
            expect(item).to have_received(:admin_policy_object_id=).with('druid:ff000df4567')
            expect(AdministrativeTags).to have_received(:create)
          end
        end
      end

      context 'when administrative has not changed' do
        it 'does not update administrative' do
          update
          expect(item).not_to have_received(:admin_policy_object_id=)
          expect(AdministrativeTags).not_to have_received(:create)
        end
      end
    end

    context 'when updating identification' do
      before do
        allow(item).to receive(:source_id=)
        allow(item).to receive(:catkey=)
        allow(identity_metadata).to receive(:barcode=)
      end

      context 'when identication has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:identification] = {
              sourceId: 'sul:8.559351',
              catalogLinks: [{ catalog: 'symphony', catalogRecordId: '10121797' }],
              barcode: '36105036289127'
            }
          end
        end

        it 'updates identification' do
          update
          expect(item).to have_received(:source_id=)
          expect(item).to have_received(:catkey=)
          expect(identity_metadata).to have_received(:barcode=)
        end
      end

      context 'when identication has not changed' do
        it 'does not update identification' do
          update
          expect(item).not_to have_received(:source_id=)
          expect(item).not_to have_received(:catkey=)
          expect(identity_metadata).not_to have_received(:barcode=)
        end
      end
    end

    context 'when updating structural without a contains block and with reading direction' do
      before do
        allow(item).to receive(:collection_ids=)
        allow(item).to receive(:rightsMetadata).and_return(
          instance_double(Dor::RightsMetadataDS, ng_xml_will_change!: nil)
        )
        allow(content_metadata).to receive(:contentType=)
        allow(AdministrativeTags).to receive(:create)
        allow(content_metadata).to receive(:ng_xml)
        allow(Cocina::ToFedora::DROAccess).to receive(:apply)
      end

      context 'when structural has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:structural] = {
              isMemberOf: ['druid:bk024qs1809'],
              hasMemberOrders: [{ viewingDirection: 'right-to-left' }]
            }
          end
        end

        it 'does not rebuild contentMetadata and does not remove bookData nodes (because a memberOrders exists)' do
          update
          expect(item).to have_received(:collection_ids=)
          expect(content_metadata).to have_received(:contentType=)
          expect(content_metadata).not_to have_received(:ng_xml)
          expect(AdministrativeTags).to have_received(:create)
          expect(Cocina::ToFedora::DROAccess).to have_received(:apply)
        end
      end

      context 'when structural has not changed' do
        it 'does not update structural' do
          update
          expect(item).not_to have_received(:collection_ids=)
          expect(content_metadata).not_to have_received(:contentType=)
          expect(AdministrativeTags).not_to have_received(:create)
          expect(Cocina::ToFedora::DROAccess).not_to have_received(:apply)
        end
      end
    end

    context 'when updating structural with a contains block' do
      before do
        allow(item).to receive(:collection_ids=)
        allow(item).to receive(:rightsMetadata).and_return(
          instance_double(Dor::RightsMetadataDS, ng_xml_will_change!: nil)
        )
        allow(content_metadata).to receive(:content=)
        allow(content_metadata).to receive(:contentType=)
        allow(content_metadata).to receive(:ng_xml)
        allow(AdministrativeTags).to receive(:create)
        allow(Cocina::ToFedora::DROAccess).to receive(:apply)
      end

      let(:cocina_attrs) do
        orig_cocina_attrs.tap do |attrs|
          attrs[:structural] = {
            contains: []
          }
        end
      end

      it 'replaces all content with newly generated contentMetadata' do
        update
        expect(item).to have_received(:collection_ids=)
        expect(content_metadata).to have_received(:content=)
        expect(content_metadata).not_to have_received(:contentType=)
        expect(content_metadata).not_to have_received(:ng_xml)
        expect(AdministrativeTags).to have_received(:create)
        expect(Cocina::ToFedora::DROAccess).to have_received(:apply)
      end
    end

    context 'when updating access' do
      before do
        allow(Cocina::ToFedora::DROAccess).to receive(:apply)
      end

      context 'when access has changed' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:access] = {
              access: 'stanford',
              download: 'stanford'
            }
          end
        end

        it 'updates access' do
          update
          expect(Cocina::ToFedora::DROAccess).to have_received(:apply)
        end
      end

      context 'when access has not changed' do
        it 'does not update access' do
          update
          expect(Cocina::ToFedora::DROAccess).not_to have_received(:apply)
        end
      end
    end

    context 'when updating type' do
      before do
        allow(content_metadata).to receive(:contentType=)
        allow(content_metadata).to receive(:ng_xml).and_return(content_metadata_ng_xml)
        allow(content_metadata_ng_xml).to receive(:xpath).and_return([book_data_node])
        allow(book_data_node).to receive(:remove)
      end

      context 'when type has changed to object' do
        let(:cocina_attrs) do
          orig_cocina_attrs.tap do |attrs|
            attrs[:type] = 'http://cocina.sul.stanford.edu/models/object.jsonld'
          end
        end

        it 'updates access and removes any bookData nodes' do
          update
          expect(content_metadata).to have_received(:contentType=)
          expect(content_metadata).to have_received(:ng_xml)
          expect(content_metadata_ng_xml).to have_received(:xpath).with('//bookData')
          expect(book_data_node).to have_received(:remove)
        end
      end

      context 'when type has not changed' do
        it 'does not update type' do
          update
          expect(content_metadata).not_to have_received(:contentType=)
        end
      end
    end
  end

  context 'when a trial' do
    let(:item) do
      instance_double(Dor::Item, pid: 'druid:bc123df4567',
                                 label: 'orig label',
                                 contentMetadata: content_metadata,
                                 descMetadata: desc_metadata,
                                 identityMetadata: identity_metadata)
    end

    let(:content_metadata) { double }

    let(:content_metadata_ng_xml) { double }

    let(:book_data_node) { double }

    let(:desc_metadata) { double }

    let(:identity_metadata) { double }

    let(:orig_cocina_attrs) do
      {
        type: 'http://cocina.sul.stanford.edu/models/media.jsonld',
        externalIdentifier: 'druid:bc123df4567',
        label: 'orig label',
        version: 1,
        access: {},
        administrative: { hasAdminPolicy: 'druid:dd999df4567' },
        identification: {
          sourceId: 'sul:8.559351',
          catalogLinks: [{ catalog: 'symphony', catalogRecordId: '10121797' }]
        }
      }
    end

    let(:trial) { true }

    before do
      allow(item).to receive(:label=)
      allow(item).to receive(:admin_policy_object_id=)
      allow(item).to receive(:source_id=)
      allow(item).to receive(:catkey=)
      allow(item).to receive(:collection_ids=)
      allow(item).to receive(:save!)
      allow(Cocina::ToFedora::Identity).to receive(:apply_label)
      allow(desc_metadata).to receive(:content=)
      allow(desc_metadata).to receive(:content_will_change!)
      allow(Cocina::ToFedora::Descriptive).to receive(:transform).and_return(Nokogiri::XML::Builder.new)
      allow(AdministrativeTags).to receive(:create)
      allow(content_metadata).to receive(:contentType=)
      allow(content_metadata).to receive(:ng_xml).and_return(content_metadata_ng_xml)
      allow(content_metadata_ng_xml).to receive(:xpath).and_return([book_data_node])
      allow(book_data_node).to receive(:remove)
      allow(Cocina::ToFedora::DROAccess).to receive(:apply)
      allow(identity_metadata).to receive(:barcode=)
    end

    it 'updates but does not save' do
      update
      expect(item).not_to have_received(:save!)
      expect(event_factory).not_to have_received(:create)
      expect(AdministrativeTags).not_to have_received(:create)

      expect(item).to have_received(:label=)
      expect(item).to have_received(:admin_policy_object_id=)
      expect(item).to have_received(:source_id=)
      expect(item).to have_received(:catkey=)
      expect(item).to have_received(:collection_ids=)
      expect(Cocina::ToFedora::Identity).to have_received(:apply_label)
      expect(desc_metadata).to have_received(:content=)
      expect(desc_metadata).to have_received(:content_will_change!)
      expect(Cocina::ToFedora::Descriptive).to have_received(:transform)
      expect(content_metadata).to have_received(:contentType=)
      allow(content_metadata).to receive(:ng_xml).and_return(content_metadata_ng_xml)
      allow(content_metadata_ng_xml).to receive(:xpath).and_return([book_data_node])
      expect(Cocina::ToFedora::DROAccess).to have_received(:apply)
      expect(identity_metadata).to have_received(:barcode=)
    end
  end
end
