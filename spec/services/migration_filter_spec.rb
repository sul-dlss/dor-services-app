# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MigrationFilter do
  let(:migrate?) { described_class.migrate?(Nokogiri::XML(rels_ext)) }

  describe '#migrate?' do
    context 'when conforms to part' do
      let(:rels_ext) do
        <<~XML
            <rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about="info:fedora/druid:bb041bm1345">
              <hydra:isGovernedBy rdf:resource="info:fedora/druid:qc410yz8746"/>
              <fedora:conformsTo rdf:resource="info:fedora/afmodel:Part"/>
              <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:bc778pm9866"/>
            </rdf:Description>
          </rdf:RDF>
        XML
      end

      it 'returns false' do
        expect(migrate?).to be(false)
      end
    end

    context 'when a part' do
      let(:rels_ext) do
        <<~XML
            <rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about="info:fedora/druid:bb041bm1345">
              <hydra:isGovernedBy rdf:resource="info:fedora/druid:qc410yz8746"/>
              <fedora-model:hasModel rdf:resource="info:fedora/afmodel:Part"/>
              <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:bc778pm9866"/>
            </rdf:Description>
          </rdf:RDF>
        XML
      end

      it 'returns false' do
        expect(migrate?).to be(false)
      end
    end

    context 'when a permission file' do
      let(:rels_ext) do
        <<~XML
            <rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about="info:fedora/druid:bb041bm1345">
              <hydra:isGovernedBy rdf:resource="info:fedora/druid:qc410yz8746"/>
              <fedora-model:hasModel rdf:resource="info:fedora/afmodel:PermissionFile"/>
              <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:bc778pm9866"/>
            </rdf:Description>
          </rdf:RDF>
        XML
      end

      it 'returns false' do
        expect(migrate?).to be(false)
      end
    end

    context 'when an item' do
      let(:rels_ext) do
        <<~XML
            <rdf:RDF xmlns:fedora="info:fedora/fedora-system:def/relations-external#" xmlns:fedora-model="info:fedora/fedora-system:def/model#" xmlns:hydra="http://projecthydra.org/ns/relations#" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <rdf:Description rdf:about="info:fedora/druid:bb041bm1345">
              <hydra:isGovernedBy rdf:resource="info:fedora/druid:qc410yz8746"/>
              <fedora-model:hasModel rdf:resource="info:fedora/afmodel:Dor_Item"/>
              <fedora:isMemberOfCollection rdf:resource="info:fedora/druid:bc778pm9866"/>
            </rdf:Description>
          </rdf:RDF>
        XML
      end

      it 'returns true' do
        expect(migrate?).to be(true)
      end
    end
  end
end
