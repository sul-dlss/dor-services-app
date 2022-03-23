# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dro do
  let(:druid) { 'druid:xz456jk0987' }

  let(:minimal_cocina_dro) do
    Cocina::Models::DRO.new({
                              cocinaVersion: '0.0.1',
                              externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.book,
                              label: 'Test DRO',
                              version: 1,
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/xz456jk0987'
                              },
                              access: { view: 'world', download: 'world' },
                              administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                              identification: { sourceId: source_id },
                              structural: { contains: [
                                {
                                  type: Cocina::Models::FileSetType.file,
                                  externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
                                  structural: {
                                    contains: [
                                      {
                                        type: Cocina::Models::ObjectType.file,
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                                        label: '00001.html',
                                        filename: '00001.html',
                                        size: 0,
                                        version: 1,
                                        hasMimeType: 'text/html',
                                        use: 'transcription',
                                        hasMessageDigests: [
                                          {
                                            type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                                          }, {
                                            type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                                          }
                                        ],
                                        access: { view: 'dark' },
                                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                                      }
                                    ]
                                  }
                                }
                              ] }
                            })
  end

  let(:cocina_dro) do
    Cocina::Models::DRO.new({
                              cocinaVersion: '0.0.1',
                              externalIdentifier: druid,
                              type: Cocina::Models::ObjectType.book,
                              label: 'Test DRO',
                              version: 1,
                              access: { view: 'world', download: 'world' },
                              administrative: { hasAdminPolicy: 'druid:hy787xj5878' },
                              description: {
                                title: [{ value: 'Test DRO' }],
                                purl: 'https://purl.stanford.edu/xz456jk0987'
                              },
                              geographic: {
                                iso19139: '<?xml version="1.0"?><rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">...'
                              },
                              identification: { sourceId: source_id },
                              structural: { contains: [
                                {
                                  type: Cocina::Models::FileSetType.file,
                                  externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/123-456-789', label: 'Page 1', version: 1,
                                  structural: {
                                    contains: [
                                      {
                                        type: Cocina::Models::ObjectType.file,
                                        externalIdentifier: 'https://cocina.sul.stanford.edu/file/123-456-789',
                                        label: '00001.html',
                                        filename: '00001.html',
                                        size: 0,
                                        version: 1,
                                        hasMimeType: 'text/html',
                                        use: 'transcription',
                                        hasMessageDigests: [
                                          {
                                            type: 'sha1', digest: 'cb19c405f8242d1f9a0a6180122dfb69e1d6e4c7'
                                          }, {
                                            type: 'md5', digest: 'e6d52da47a5ade91ae31227b978fb023'
                                          }
                                        ],
                                        access: { view: 'dark' },
                                        administrative: { publish: false, sdrPreserve: true, shelve: false }
                                      }
                                    ]
                                  }
                                }
                              ] }
                            })
  end

  let(:source_id) { 'googlebooks:9999999' }

  describe 'to_h' do
    context 'with a DRO lacking structural metadata' do
      let(:dro) { create(:dro, external_identifier: druid, structural: nil) }

      it 'returns a valid Cocina hash' do
        expect { Cocina::Models::DRO.new(dro.to_h) }.not_to raise_error(Cocina::Models::ValidationError)
      end
    end
  end

  describe 'to_cocina' do
    context 'with minimal DRO' do
      let(:dro) { create(:dro, external_identifier: druid) }
      let(:source_id) { dro.identification['sourceId'] }

      it 'returns a Cocina::Model::DRO' do
        expect(dro.to_cocina).to eq(minimal_cocina_dro)
      end
    end

    context 'with complete DRO' do
      let(:dro) { create(:dro, :with_geographic, external_identifier: druid) }
      let(:source_id) { dro.identification['sourceId'] }

      it 'returns a Cocina::Model::DRO' do
        expect(dro.to_cocina).to eq(cocina_dro)
      end
    end
  end

  describe 'from_cocina' do
    context 'with a minimal DRO' do
      let(:dro) { described_class.from_cocina(minimal_cocina_dro) }

      it 'returns a Dro' do
        expect(dro).to be_a(described_class)
        expect(dro.external_identifier).to eq(minimal_cocina_dro.externalIdentifier)
        expect(dro.cocina_version).to eq(minimal_cocina_dro.cocinaVersion)
        expect(dro.content_type).to eq(minimal_cocina_dro.type)
        expect(dro.label).to eq(minimal_cocina_dro.label)
        expect(dro.version).to eq(minimal_cocina_dro.version)
        expect(dro.access).to eq(minimal_cocina_dro.access.to_h.with_indifferent_access)
        expect(dro.administrative).to eq(minimal_cocina_dro.administrative.to_h.with_indifferent_access)
        expect(dro.description).to eq(cocina_dro.description.to_h.with_indifferent_access)
        expect(dro.identification).to eq(cocina_dro.identification.to_h.with_indifferent_access)
        expect(dro.structural).to eq(cocina_dro.structural.to_h.with_indifferent_access)
        expect(dro.geographic).to be_nil
      end
    end

    context 'with a complete DRO' do
      let(:dro) { described_class.from_cocina(cocina_dro) }

      it 'returns a Dro' do
        expect(dro).to be_a(described_class)
        expect(dro.external_identifier).to eq(cocina_dro.externalIdentifier)
        expect(dro.cocina_version).to eq(cocina_dro.cocinaVersion)
        expect(dro.content_type).to eq(cocina_dro.type)
        expect(dro.label).to eq(cocina_dro.label)
        expect(dro.version).to eq(cocina_dro.version)
        expect(dro.access).to eq(cocina_dro.access.to_h.with_indifferent_access)
        expect(dro.administrative).to eq(cocina_dro.administrative.to_h.with_indifferent_access)
        expect(dro.description).to eq(cocina_dro.description.to_h.with_indifferent_access)
        expect(dro.identification).to eq(cocina_dro.identification.to_h.with_indifferent_access)
        expect(dro.structural).to eq(cocina_dro.structural.to_h.with_indifferent_access)
        expect(dro.geographic).to eq(cocina_dro.geographic.to_h.with_indifferent_access)
      end
    end
  end

  describe 'sourceId uniqueness' do
    let(:cocina_object1) do
      minimal_cocina_dro.new(identification: { sourceId: 'sul:PC0170_s3_USC_2010-10-09_141959_0031' })
    end

    context 'when sourceId is unique' do
      let(:cocina_object2) do
        minimal_cocina_dro.new(externalIdentifier: 'druid:dd645sg2172', identification: { sourceId: 'sul:PC0170_s3_USC_2010-10-09_141959_0032' })
      end

      it 'does not raise' do
        described_class.upsert_cocina(cocina_object1)
        described_class.upsert_cocina(cocina_object2)
      end
    end

    context 'when sourceId is not unique' do
      let(:cocina_object2) do
        minimal_cocina_dro.new(externalIdentifier: 'druid:dd645sg2172', identification: { sourceId: 'sul:PC0170_s3_USC_2010-10-09_141959_0031' })
      end

      it 'raises' do
        described_class.upsert_cocina(cocina_object1)
        expect { described_class.upsert_cocina(cocina_object2) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
