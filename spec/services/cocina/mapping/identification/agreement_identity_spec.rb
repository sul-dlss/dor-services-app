# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'Agreement Object Identification Fedora Cocina mapping' do
  # Required: agreement_id, label, admin_policy_id, collection_ids, identity_metadata_xml, cocina_props
  # Optional: catkey, source_id_source, source_id, other_id_name, other_id, roundtrip_identity_metadata_xml

  # Normalization notes for later:
  #  otherId of type uuid -> normalize out (keep catkey, barcode ...)  shelfseq, callseq? dissertationid (YES?)?,
  #  tags (non-release) -> normalize out
  #  adminPolicy -> normalize out (we use RELS-EXT)
  #  sourceId -> we need to KEEP - every item should have a sourceId, as should agreements
  #  releaseTag -> we need to KEEP
  #  missing collections OK -- don't produce cocina with nil druid for collection

  let(:namespaced_source_id) { defined?(source_id) && defined?(source_id_source) ? "#{source_id_source}:#{source_id}" : nil }
  let(:namespaced_other_ids) do
    other_id_nodes = Nokogiri::XML(identity_metadata_xml).xpath('//identityMetadata/otherId')
    other_id_nodes.map { |other_id_node| "#{other_id_node['name']}:#{other_id_node.text}" }
  end
  let(:mods_xml) do
    <<~XML
      <mods #{MODS_ATTRIBUTES}>
        <titleInfo>
          <title>agreement title</title>
        </titleInfo>
      </mods>
    XML
  end
  # using a mock rather than every example having all relevant datastreams
  let(:fedora_agreement_mock) do
    instance_double(Dor::Agreement,
                    pid: agreement_id,
                    id: agreement_id, # see app/services/cocina/from_fedora/administrative.rb:22
                    objectLabel: [label],
                    label: label,
                    current_version: '1',
                    admin_policy_object_id: defined?(admin_policy_id) ? admin_policy_id : nil,
                    catkey: defined?(catkey) ? catkey : nil,
                    source_id: namespaced_source_id, # see app/services/cocina/from_fedora/identification.rb:30
                    otherId: namespaced_other_ids, # see app/services/cocina/from_fedora/identification.rb:36
                    collections: collection_ids.map { |id| Dor::Collection.new(pid: id) },
                    identityMetadata: Dor::IdentityMetadataDS.from_xml(identity_metadata_xml),
                    descMetadata: Dor::DescMetadataDS.from_xml(mods_xml),
                    embargoMetadata: Dor::EmbargoMetadataDS.new,
                    contentMetadata: Dor::ContentMetadataDS.new,
                    rightsMetadata: Dor::RightsMetadataDS.new)
  end
  let(:mapped_cocina_props) { Cocina::FromFedora::DRO.props(fedora_agreement_mock) }
  let(:normalized_orig_identity_xml) do
    # the starting identityMetadata.xml is normalized to address discrepancies found against identityMetadata roundtripped
    #  from data store (Fedora) and back, per Andrew's specifications.
    #  E.g., <adminPolicy> is removed as that information will not be carried over and is retrieved from RELS-EXT
    Cocina::Normalizers::IdentityNormalizer.normalize(identity_ng_xml: Nokogiri::XML(identity_metadata_xml)).to_xml
  end
  let(:roundtrip_identity_md_xml) { defined?(roundtrip_identity_metadata_xml) ? roundtrip_identity_metadata_xml : identity_metadata_xml }
  let(:roundtrip_fedora_agreement) do
    cocina_dro = Cocina::Models::DRO.new(mapped_cocina_props)
    fedora_agreement = Dor::Agreement.new(pid: cocina_dro.externalIdentifier,
                                          source_id: cocina_dro.identification.sourceId,
                                          catkey: Cocina::ObjectCreator.new.send(:catkey_for, cocina_dro),
                                          label: Cocina::ObjectCreator.new.send(:truncate_label, cocina_dro.label))
    Cocina::ToFedora::Identity.initialize_identity(fedora_agreement)
    Cocina::ToFedora::Identity.apply_label(fedora_agreement, label: cocina_dro.label)
    fedora_agreement.identityMetadata.barcode = cocina_dro.identification.barcode
    fedora_agreement
  end
  let(:mapped_roundtrip_identity_xml) do
    Cocina::ToFedora::Identity.initialize_identity(roundtrip_fedora_agreement)
    Cocina::ToFedora::Identity.apply_label(roundtrip_fedora_agreement, label: mapped_cocina_props[:label])
    roundtrip_fedora_agreement.identityMetadata.to_xml
  end

  before do
    allow(fedora_agreement_mock).to receive(:is_a?).with(Dor::Agreement).and_return(true)
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina Descriptive model' do
      expect { Cocina::Models::DRO.new(cocina_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_cocina_props).to be_deep_equal(cocina_props)
    end
  end

  context 'when mapping from Cocina to (roundtrip) Fedora' do
    it 'identityMetadata roundtrips thru cocina model to original identityMetadata.xml' do
      expect(mapped_roundtrip_identity_xml).to be_equivalent_to(roundtrip_identity_md_xml)
    end

    it 'identityMetadata roundtrips thru cocina maps to normalized original identityMetadata.xml' do
      expect(mapped_roundtrip_identity_xml).to be_equivalent_to normalized_orig_identity_xml
    end
  end

  context 'when mapping from roundtrip Fedora to (roundtrip) Cocina' do
    let(:roundtrip_catkey) do
      catalog_link = mapped_cocina_props[:identification][:catalogLinks]&.find { |clink| clink[:catalog] == 'symphony' }
      catalog_link[:catalogRecordId] if catalog_link
    end
    let(:roundtrip_namespaced_other_ids) do
      other_id_nodes = Nokogiri::XML(mapped_roundtrip_identity_xml).xpath('//identityMetadata/otherId')
      other_id_nodes.map { |other_id_node| "#{other_id_node['name']}:#{other_id_node.text}" }
    end
    let(:roundtrip_collections) do
      mapped_cocina_props[:structural][:isMemberOf]&.map do |collection_id|
        instance_double(Dor::Collection,
                        pid: collection_id,
                        id: collection_id)
      end
    end
    # using a mock rather than every example having all relevant datastreams
    let(:roundtrip_fedora_agreement_mock) do
      instance_double(Dor::Agreement,
                      pid: mapped_cocina_props[:externalIdentifier],
                      id: mapped_cocina_props[:externalIdentifier], # see app/services/cocina/from_fedora/administrative.rb:22
                      objectLabel: [label],
                      label: mapped_cocina_props[:label],
                      current_version: '1',
                      admin_policy_object_id: mapped_cocina_props[:administrative][:hasAdminPolicy],
                      collections: roundtrip_collections,
                      catkey: roundtrip_catkey,
                      source_id: mapped_cocina_props[:identification][:sourceId],
                      otherId: namespaced_other_ids, # see app/services/cocina/from_fedora/identification.rb:36
                      identityMetadata: Dor::IdentityMetadataDS.from_xml(mapped_roundtrip_identity_xml),
                      descMetadata: Dor::DescMetadataDS.from_xml(mods_xml),
                      embargoMetadata: Dor::EmbargoMetadataDS.new,
                      contentMetadata: Dor::ContentMetadataDS.new,
                      rightsMetadata: Dor::RightsMetadataDS.new)
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::DRO.props(roundtrip_fedora_agreement_mock) }

    before do
      allow(roundtrip_fedora_agreement_mock).to receive(:is_a?).with(Dor::Agreement).and_return(true)
    end

    it 'roundtrip Fedora maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end

  context 'when mapping from normalized orig Fedora identity_metadata_xml to (roundtrip) Cocina' do
    # using a mock rather than every example having all relevant datastreams
    let(:normalized_orig_fedora_agreement_mock) do
      instance_double(Dor::Agreement,
                      pid: agreement_id,
                      id: agreement_id, # see app/services/cocina/from_fedora/administrative.rb:22
                      objectLabel: [label],
                      label: label,
                      current_version: '1',
                      admin_policy_object_id: defined?(admin_policy_id) ? admin_policy_id : nil,
                      catkey: defined?(catkey) ? catkey : nil,
                      source_id: namespaced_source_id, # see app/services/cocina/from_fedora/identification.rb:30
                      otherId: namespaced_other_ids, # see app/services/cocina/from_fedora/identification.rb:36
                      collections: collection_ids.map { |id| Dor::Collection.new(pid: id) },
                      identityMetadata: Dor::IdentityMetadataDS.from_xml(normalized_orig_identity_xml),
                      descMetadata: Dor::DescMetadataDS.from_xml(mods_xml),
                      embargoMetadata: Dor::EmbargoMetadataDS.new,
                      contentMetadata: Dor::ContentMetadataDS.new,
                      rightsMetadata: Dor::RightsMetadataDS.new)
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::DRO.props(normalized_orig_fedora_agreement_mock) }

    before do
      allow(normalized_orig_fedora_agreement_mock).to receive(:is_a?).with(Dor::Agreement).and_return(true)
    end

    it 'roundtrip Fedora maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end
end

RSpec.describe 'Fedora Agreement Object identityMetadata <--> Cocina Identification mappings' do
  # NOTE: access tested in mapping/access/dro_access_spec.rb
  let(:access_props) do
    {
      access: 'dark',
      download: 'none'
    }
  end
  # NOTE: description tested in mapping/descriptive/mods
  let(:description_props) do
    {
      title: [
        value: 'agreement title'
      ],
      purl: "https://purl.stanford.edu/#{agreement_id.split(':').last}"
    }
  end

  context 'with agreement object' do
    it_behaves_like 'Agreement Object Identification Fedora Cocina mapping' do
      let(:agreement_id) { 'druid:bq655xb7335' }
      let(:label) { 'Gale hText agreement' }
      let(:admin_policy_id) { 'druid:hv992ry2431' } # from RELS-EXT
      let(:collection_ids) { [] } # no collection ids from RELS-EXT
      let(:source_id_source) { 'Hydrus' }
      let(:source_id) { 'item-hfrost-2014-03-17T21:29:12.331Z' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{agreement_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>agreement</objectType>
            <otherId name="uuid">2f05815a-ae1b-11e3-8209-0050569b3c6e</otherId>
            <tag>Remediated By : 5.11.0</tag>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{agreement_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>agreement</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: agreement_id,
          type: Cocina::Models::Vocab.agreement,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {},
          access: access_props,
          description: description_props
        }
      end
    end
  end
end
