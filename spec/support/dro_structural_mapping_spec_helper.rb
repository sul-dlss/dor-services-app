# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'DRO Structural Fedora Cocina mapping' do
  # Required: content_xml, cocina_structural_props
  # Optional: roundtrip_content_xml

  let(:fedora_item) { Dor::Item.new }
  let(:druid) { 'druid:hv992ry2431' }
  let(:notifier) { Cocina::FromFedora::DataErrorNotifier.new(druid: druid) }
  let(:object_type) { Cocina::Models::Vocab.book }
  let(:mapped_structural_props) do
    Cocina::FromFedora::DroStructural.props(fedora_item, type: object_type, notifier: notifier)
  end
  let(:roundtrip_content_metadata_xml) { defined?(roundtrip_content_xml) ? roundtrip_content_xml : content_xml }
  let(:normalized_roundtrip_content_metadata_xml) do
    Cocina::Normalizers::ContentMetadataNormalizer.normalize_roundtrip(content_ng_xml: Nokogiri::XML(roundtrip_content_metadata_xml)).to_xml
  end
  let(:normalized_orig_content_xml) do
    orig_content_metadata_ds = Dor::ContentMetadataDS.from_xml(content_xml)
    Cocina::Normalizers::ContentMetadataNormalizer.normalize(content_ng_xml: orig_content_metadata_ds.ng_xml,
                                                             druid: druid).to_xml
  end
  let(:cocina_structural) { Cocina::Models::DROStructural.new(cocina_structural_props) }
  let(:roundtrip_structural_props) do
    defined?(roundtrip_cocina_structural_props) ? roundtrip_cocina_structural_props : cocina_structural_props
  end

  let(:rights_xml) do
    <<~XML
      <rightsMetadata>
        <access type="discover">
          <machine>
            <world/>
          </machine>
        </access>
        <access type="read">
          <machine>
            <world/>
          </machine>
        </access>
      </rightsMetadata>
    XML
  end

  before do
    rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
    allow(fedora_item).to receive(:rightsMetadata).and_return(rights_metadata_ds)
    content_metadata_ds = Dor::ContentMetadataDS.from_xml(content_xml)
    allow(fedora_item).to receive(:contentMetadata).and_return(content_metadata_ds)
    allow(Cocina::IdGenerator).to receive(:generate_or_existing_fileset_id).and_return('http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f')
    allow(Cocina::IdGenerator).to receive(:generate_file_id).and_return('http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181')
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina DROStructural' do
      expect { Cocina::Models::DROStructural.new(mapped_structural_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_structural_props).to be_deep_equal(cocina_structural_props)
    end
  end

  context 'when mapping from Cocina to Fedora' do
    let(:mapped_content_xml) do
      Cocina::ToFedora::ContentMetadataGenerator.generate(druid: druid, type: object_type,
                                                          structural: cocina_structural)
    end
    let(:normalized_mapped_content_xml) do
      Cocina::Normalizers::ContentMetadataNormalizer.normalize_roundtrip(content_ng_xml: Nokogiri::XML(mapped_content_xml)).to_xml
    end

    it 'contentMetadata roundtrips thru cocina model to provided expected contentMetadata.xml' do
      expect(normalized_mapped_content_xml).to be_equivalent_to(normalized_roundtrip_content_metadata_xml)
    end

    it 'contentMetadata roundtrips thru cocina model to normalized original contentMetadata.xml' do
      expect(normalized_mapped_content_xml).to be_equivalent_to(normalized_orig_content_xml)
    end
  end

  context 'when mapping from roundtrip Fedora to (roundtrip) Cocina' do
    let(:roundtrip_fedora_item) { Dor::Item.new }
    let(:actual_roundtrip_structural_props) do
      Cocina::FromFedora::DroStructural.props(roundtrip_fedora_item, type: object_type, notifier: notifier)
    end

    before do
      roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
      allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
      roundtrip_content_metadata_ds = Dor::ContentMetadataDS.from_xml(roundtrip_content_metadata_xml)
      allow(roundtrip_fedora_item).to receive(:contentMetadata).and_return(roundtrip_content_metadata_ds)
    end

    it 'roundtrip Fedora maps to expected Cocina object props' do
      expect(actual_roundtrip_structural_props).to be_deep_equal(roundtrip_structural_props)
    end
  end

  context 'when mapping from normalized orig Fedora content_xml to (roundtrip) Cocina' do
    let(:roundtrip_fedora_item) { Dor::Item.new }
    let(:actual_roundtrip_structural_props) do
      Cocina::FromFedora::DroStructural.props(roundtrip_fedora_item, type: object_type, notifier: notifier)
    end

    before do
      roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
      allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
      roundtrip_content_metadata_ds = Dor::ContentMetadataDS.from_xml(normalized_orig_content_xml)
      allow(roundtrip_fedora_item).to receive(:contentMetadata).and_return(roundtrip_content_metadata_ds)
    end

    it 'normalized Fedora content_xml maps to expected Cocina object props' do
      expect(actual_roundtrip_structural_props).to be_deep_equal(roundtrip_structural_props)
    end
  end
end
