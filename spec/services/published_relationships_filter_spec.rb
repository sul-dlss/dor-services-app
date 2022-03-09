# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishedRelationshipsFilter do
  subject(:service) { described_class.new(cocina_object) }

  describe '#xml' do
    subject(:doc) { service.xml }

    before do
      allow(VirtualObject).to receive(:for).and_return([{ id: 'druid:hj097bm8879' }])
    end

    context 'with a DRO' do
      let(:cocina_object) do
        Cocina::Models::DRO.new(
          {
            externalIdentifier: 'druid:bc123df4567',
            type: Cocina::Models::ObjectType.object,
            label: 'foo',
            version: 1,
            access: {},
            description: {
              title: [{ value: 'foo' }],
              purl: 'https://purl.stanford.edu/bc123df4567'
            },
            administrative: {
              hasAdminPolicy: 'druid:df123cd4567'
            },
            structural: {
              isMemberOf: ['druid:xh235dd9059']
            }
          }
        )
      end

      it 'serializes the relations as RDF' do
        expect(doc).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#">
            <rdf:Description rdf:about="info:fedora/druid:bc123df4567">
              <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:xh235dd9059"/>
              <fedora:isConstituentOf rdf:resource="info:fedora/druid:hj097bm8879"/>
            </rdf:Description>
          </rdf:RDF>
        XML
      end
    end

    context 'with a Collection' do
      let(:cocina_object) do
        Cocina::Models::Collection.new(
          {
            externalIdentifier: 'druid:bc123df4567',
            type: Cocina::Models::ObjectType.collection,
            label: 'foo',
            version: 1,
            description: {
              title: [{ value: 'foo' }],
              purl: 'https://purl.stanford.edu/bc123df4567'
            },
            access: {},
            administrative: {
              hasAdminPolicy: 'druid:df123cd4567'
            }
          }
        )
      end

      it 'serializes the relations as RDF' do
        expect(doc).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
          <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:fedora="info:fedora/fedora-system:def/relations-external#">
            <rdf:Description rdf:about="info:fedora/druid:bc123df4567" />
          </rdf:RDF>
        XML
      end
    end
  end
end
