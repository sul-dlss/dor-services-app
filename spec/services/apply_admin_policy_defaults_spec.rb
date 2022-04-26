# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplyAdminPolicyDefaults do
  let(:apo_druid) { 'druid:df123cd4567' }
  let(:object_druid) { 'druid:bc123df4567' }
  let(:default_access) do
    Cocina::Models::DROAccess.new(
      view: 'world',
      download: 'world'
    ).to_h
  end
  let(:cocina_object) do
    Cocina::Models::DRO.new(
      externalIdentifier: object_druid,
      version: 1,
      type: Cocina::Models::ObjectType.object,
      label: 'Dummy DRO',
      description: {
        title: [{ value: 'Dummy DRO' }],
        purl: "https://purl.stanford.edu/#{object_druid.delete_prefix('druid:')}"
      },
      access: access_props,
      administrative: { hasAdminPolicy: apo_druid },
      structural: {},
      identification: { sourceId: 'sul:123' }
    )
  end
  let(:workflow_state) { 'Registered' }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, status: status_client) }
  let(:status_client) { instance_double(Dor::Workflow::Client::Status, display_simplified: workflow_state) }
  let(:access_props) { {} }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
  end

  describe '.apply' do
    let(:instance) { instance_double(described_class, apply: nil) }

    before do
      allow(described_class).to receive(:new).and_return(instance)
    end

    it 'calls #apply on a new instance' do
      described_class.apply(cocina_object: instance_double(Cocina::Models::DRO))
      expect(instance).to have_received(:apply).once
    end
  end

  describe '#new' do
    context 'with a collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(
          externalIdentifier: object_druid,
          version: 1,
          type: Cocina::Models::ObjectType.collection,
          label: 'Dummy Collection',
          description: {
            title: [{ value: 'Dummy Collection' }],
            purl: "https://purl.stanford.edu/#{object_druid.delete_prefix('druid:')}"
          },
          access: {},
          administrative: { hasAdminPolicy: apo_druid },
          identification: { sourceId: 'sul:123' }
        )
      end

      it 'validates the object type and creates an instance' do
        expect { described_class.new(cocina_object: cocina_object) }.not_to raise_error
      end
    end

    context 'with a DRO' do
      it 'validates the object type and creates an instance' do
        expect { described_class.new(cocina_object: cocina_object) }.not_to raise_error
      end
    end

    context 'with an APO' do
      let(:cocina_object) do
        Cocina::Models::AdminPolicy.new(
          externalIdentifier: object_druid,
          version: 1,
          type: Cocina::Models::ObjectType.admin_policy,
          label: 'Dummy APO',
          administrative: {
            hasAdminPolicy: 'druid:hv992ry2431',
            hasAgreement: 'druid:bc753qt7345',
            accessTemplate: default_access
          }
        )
      end

      it 'invalidates the object type and raises a custom exception' do
        expect { described_class.new(cocina_object: cocina_object) }.to raise_error(
          described_class::UnsupportedObjectTypeError,
          "#{object_druid} is a Cocina::Models::AdminPolicy and this type cannot have APO defaults applied"
        )
      end
    end

    described_class::ALLOWED_WORKFLOW_STATES.each do |workflow_state|
      context "with an object in '#{workflow_state}' state" do
        let(:workflow_state) { workflow_state }

        it 'validates the object type and creates an instance' do
          expect { described_class.new(cocina_object: cocina_object) }.not_to raise_error
        end
      end
    end

    ['Unknown Status', 'In accessioning', 'Accessioned'].each do |workflow_state|
      context "with an object in '#{workflow_state}' state" do
        let(:workflow_state) { workflow_state }

        it 'invalidates the object type and raises a custom exception' do
          expect { described_class.new(cocina_object: cocina_object) }.to raise_error(
            described_class::UnsupportedWorkflowStateError,
            "#{object_druid} is in a state in which it cannot be modified (#{workflow_state}): " \
            'APO defaults can only be applied when an object is either registered or opened for versioning'
          )
        end
      end
    end
  end

  describe '#apply' do
    let(:instance) { described_class.new(cocina_object: cocina_object) }
    let(:cocina_admin_policy) do
      Cocina::Models::AdminPolicy.new(
        externalIdentifier: apo_druid,
        version: 1,
        type: Cocina::Models::ObjectType.admin_policy,
        label: 'Dummy APO',
        administrative: {
          hasAdminPolicy: 'druid:hv992ry2431',
          hasAgreement: 'druid:bc753qt7345',
          accessTemplate: default_access
        }
      )
    end

    before do
      allow(CocinaObjectStore).to receive(:find).with(object_druid).and_return(cocina_object)
      allow(CocinaObjectStore).to receive(:find).with(apo_druid).and_return(cocina_admin_policy)
      allow(CocinaObjectStore).to receive(:save)
      instance.apply
    end

    context 'with a DRO that lack structural metadata' do
      context 'with dark access' do
        it 'copies APO accessTemplate to item access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: default_access))
        end
      end

      context 'with location-based access' do
        let(:access_props) do
          {
            view: 'location-based',
            download: 'location-based',
            location: 'spec'
          }
        end

        it 'copies APO accessTemplate to item access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: default_access))
        end
      end
    end

    context 'with a collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(
          externalIdentifier: object_druid,
          version: 1,
          type: Cocina::Models::ObjectType.collection,
          label: 'Dummy Collection',
          description: {
            title: [{ value: 'Dummy Collection' }],
            purl: "https://purl.stanford.edu/#{object_druid.delete_prefix('druid:')}"
          },
          access: {},
          administrative: { hasAdminPolicy: apo_druid },
          identification: { sourceId: 'sul:123' }
        )
      end

      context 'when APO specifies citation-only accessTemplate' do
        let(:default_access) do
          {
            view: 'citation-only',
            download: 'none'
          }
        end
        let(:expected_access) do
          {
            view: 'world'
          }
        end

        it 'maps to world collection access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: expected_access))
        end
      end

      context 'when APO specifies location-based accessTemplate' do
        let(:default_access) do
          {
            view: 'location-based',
            download: 'none',
            location: 'music'
          }
        end
        let(:expected_access) do
          {
            view: 'world'
          }
        end

        it 'maps to world collection access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: expected_access))
        end
      end

      context 'when APO specifies Stanford (or CDL) accessTemplate' do
        let(:default_access) do
          {
            view: 'stanford',
            download: 'none',
            controlledDigitalLending: true
          }
        end
        let(:expected_access) do
          {
            view: 'world'
          }
        end

        it 'maps to world collection access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: expected_access))
        end
      end

      context 'when APO specifies dark accessTemplate' do
        let(:default_access) do
          {
            view: 'dark',
            download: 'none'
          }
        end
        let(:expected_access) do
          {
            view: 'dark'
          }
        end

        it 'maps to dark collection access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: expected_access))
        end
      end
    end

    context 'with a DRO that has structural metadata' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(
          externalIdentifier: object_druid,
          version: 1,
          type: Cocina::Models::ObjectType.object,
          label: 'Dummy Object',
          description: {
            title: [{ value: 'Dummy Object' }],
            purl: "https://purl.stanford.edu/#{object_druid.delete_prefix('druid:')}"
          },
          access: {},
          administrative: { hasAdminPolicy: apo_druid },
          structural: {
            contains: [before_file_set]
          },
          identification: { sourceId: 'sul:123' }
        )
      end
      let(:before_file_set) do
        {
          externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
          version: 1,
          type: Cocina::Models::FileSetType.file,
          label: 'Page 1',
          structural: {
            contains: [
              {
                externalIdentifier: 'https://cocina.sul.stanford.edu/file/223-456-789',
                version: 1,
                type: Cocina::Models::ObjectType.file,
                filename: '00001.jp2',
                label: '00001.jp2',
                hasMimeType: 'image/jp2',
                administrative: {
                  publish: false,
                  sdrPreserve: true,
                  shelve: false
                },
                access: {
                  view: 'dark',
                  download: 'none'
                },
                hasMessageDigests: []
              }
            ]
          }
        }
      end

      context 'when APO uses default default rights' do
        let(:file_set_with_default_access) do
          {
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
            version: 1,
            type: Cocina::Models::FileSetType.file,
            label: 'Page 1',
            structural: {
              contains: [
                {
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/223-456-789',
                  version: 1,
                  type: Cocina::Models::ObjectType.file,
                  filename: '00001.jp2',
                  label: '00001.jp2',
                  hasMimeType: 'image/jp2',
                  administrative: {
                    publish: false,
                    sdrPreserve: true,
                    shelve: false
                  },
                  access: default_access,
                  hasMessageDigests: []
                }
              ]
            }
          }
        end

        it 'copies APO accessTemplate to item access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: default_access, structural: { contains: [file_set_with_default_access] }))
        end
      end

      context 'when APO specifies custom default object rights' do
        let(:default_access) do
          Cocina::Models::DROAccess.new(
            view: 'dark',
            download: 'none',
            useAndReproductionStatement: 'Use at will.',
            license: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode'
          ).to_h
        end
        let(:file_set_with_custom_access) do
          {
            externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/234-567-890',
            version: 1,
            type: Cocina::Models::FileSetType.file,
            label: 'Page 1',
            structural: {
              contains: [
                {
                  externalIdentifier: 'https://cocina.sul.stanford.edu/file/223-456-789',
                  version: 1,
                  type: Cocina::Models::ObjectType.file,
                  filename: '00001.jp2',
                  label: '00001.jp2',
                  hasMimeType: 'image/jp2',
                  administrative: {
                    publish: false,
                    sdrPreserve: true,
                    shelve: false
                  },
                  access: default_access.slice(:view, :download, :location, :controlledDigitalLending),
                  hasMessageDigests: []
                }
              ]
            }
          }
        end

        it 'copies APO accessTemplate to item access' do
          expect(CocinaObjectStore).to have_received(:save)
            .once
            .with(cocina_object_with(access: default_access, structural: { contains: [file_set_with_custom_access] }))
        end
      end
    end
  end
end
