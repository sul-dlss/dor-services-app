# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublishedRelationshipsFilter do
  subject(:service) { described_class.new(cocina_object, constituents) }

  let(:constituents) { [{ id: 'druid:hj097bm8879' }] }

  describe '#xml' do
    subject(:doc) { service.xml }

    context 'with a DRO' do
      let(:cocina_object) do
        build(:dro, id: 'druid:bc123df4567').new(
          structural: {
            isMemberOf: ['druid:xh235dd9059']
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
      let(:cocina_object) { build(:collection, id: 'druid:bc123df4567') }

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
