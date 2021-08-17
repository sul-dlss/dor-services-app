# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'APO Identification Fedora Cocina mapping' do
  # Required: pid, label, identity_metadata_xml, cocina_props
  # Optional: admin_policy_id, agreement_object_id, roundtrip_identity_metadata_xml

  # Normalization notes:
  #  otherId of type uuid -> normalize out
  #  tags -> normalize out
  #  agreementId, adminPolicy -> normalize out (we use RELS-EXT)
  #  sourceId -> we need to KEEP

  let(:mods_ng_xml) do
    Nokogiri::XML <<~XML
      <mods #{MODS_ATTRIBUTES}>
        <titleInfo>
          <title>APO title</title>
        </titleInfo>
      </mods>
    XML
  end
  # NOTE: tested in mapping/administrative/apo_administrative_spec.rb
  let(:default_object_rights_xml) do
    <<~XML
      <rightsMetadata/>
    XML
  end
  # NOTE: tested in mapping/administrative/apo_administrative_spec.rb
  let(:administrative_metadata_xml) do
    <<~XML
      <administrativeMetadata/>
    XML
  end
  let(:admin_policy_id) { defined?(admin_policy_id) ? admin_policy_id : nil }
  let(:agreement_object_id) { defined?(agreement_object_id) ? agreement_object_id : nil }
  let(:fedora_apo_mock) do
    instance_double(Dor::AdminPolicyObject,
                    pid: pid,
                    label: label,
                    current_version: '1',
                    admin_policy_object_id: admin_policy_id,
                    agreement_object_id: agreement_object_id,
                    identityMetadata: Dor::IdentityMetadataDS.from_xml(identity_metadata_xml),
                    descMetadata: instance_double(Dor::DescMetadataDS, ng_xml: mods_ng_xml),
                    defaultObjectRights: instance_double(Dor::DefaultObjectRightsDS, content: default_object_rights_xml),
                    administrativeMetadata: Dor::AdministrativeMetadataDS.from_xml(administrative_metadata_xml),
                    roleMetadata: instance_double(Dor::RoleMetadataDS, find_by_xpath: []))
  end
  let(:mapped_cocina_props) { Cocina::FromFedora::APO.props(fedora_apo_mock) }
  let(:normalized_orig_identity_xml) do
    # the starting identityMetadata.xml is normalized to address discrepancies found against identityMetadata roundtripped
    #  from data store (Fedora) and back, per Andrew's specifications.
    #  E.g., <adminPolicy> is removed as that information will not be carried over and is retrieved from RELS-EXT
    Cocina::Normalizers::IdentityNormalizer.normalize(identity_ng_xml: Nokogiri::XML(identity_metadata_xml)).to_xml
  end
  let(:roundtrip_identity_metadata_xml) { defined?(roundtrip_identity_metadata_xml) ? roundtrip_identity_metadata_xml : identity_metadata_xml }

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina Descriptive model' do
      expect { Cocina::Models::AdminPolicy.new(cocina_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_cocina_props).to be_deep_equal(cocina_props)
    end
  end

  context 'when mapping from Cocina to (roundtrip) Fedora' do
    let(:mapped_fedora_apo) do
      Dor::AdminPolicyObject.new(pid: mapped_cocina_props[:externalIdentifier],
                                 admin_policy_object_id: mapped_cocina_props[:administrative][:hasAdminPolicy],
                                 agreement_object_id: mapped_cocina_props[:administrative][:referencesAgreement],
                                 # source_id: cocina_admin_policy.identification.sourceId,
                                 label: mapped_cocina_props[:label])
    end
    let(:mapped_roundtrip_identity_xml) do
      Cocina::ToFedora::Identity.initialize_identity(mapped_fedora_apo)
      Cocina::ToFedora::Identity.apply_label(mapped_fedora_apo, label: mapped_cocina_props[:label])
      mapped_fedora_apo.identityMetadata.to_xml
    end

    it 'identityMetadata roundtrips thru cocina model to expected roundtrip identityMetadata.xml' do
      expect(mapped_roundtrip_identity_xml).to be_equivalent_to(roundtrip_identity_metadata_xml)
    end

    it 'identityMetadata roundtrips thru cocina maps to normalized original identityMetadata.xml' do
      expect(mapped_roundtrip_identity_xml).to be_equivalent_to normalized_orig_identity_xml
    end
  end

  context 'when mapping from roundtrip Fedora to Cocina' do
    let(:roundtrip_fedora_apo_mock) do
      instance_double(Dor::AdminPolicyObject,
                      pid: mapped_cocina_props[:externalIdentifier],
                      label: mapped_cocina_props[:label],
                      current_version: '1',
                      admin_policy_object_id: mapped_cocina_props[:administrative][:hasAdminPolicy],
                      agreement_object_id: mapped_cocina_props[:administrative][:referencesAgreement],
                      identityMetadata: Dor::IdentityMetadataDS.from_xml(identity_metadata_xml),
                      descMetadata: instance_double(Dor::DescMetadataDS, ng_xml: mods_ng_xml),
                      defaultObjectRights: instance_double(Dor::DefaultObjectRightsDS, content: default_object_rights_xml),
                      administrativeMetadata: Dor::AdministrativeMetadataDS.from_xml(administrative_metadata_xml),
                      roleMetadata: instance_double(Dor::RoleMetadataDS, find_by_xpath: []))
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::APO.props(roundtrip_fedora_apo_mock) }

    it 'roundtrip Fedora maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end

  context 'when mapping from normalized orig Fedora identity_metadata_xml to (roundtrip) Cocina' do
    let(:normalized_orig_fedora_apo_mock) do
      instance_double(Dor::AdminPolicyObject,
                      pid: pid,
                      label: label,
                      current_version: '1',
                      admin_policy_object_id: admin_policy_id,
                      agreement_object_id: agreement_object_id,
                      identityMetadata: Dor::IdentityMetadataDS.from_xml(normalized_orig_identity_xml),
                      descMetadata: instance_double(Dor::DescMetadataDS, ng_xml: mods_ng_xml),
                      defaultObjectRights: instance_double(Dor::DefaultObjectRightsDS, content: default_object_rights_xml),
                      administrativeMetadata: Dor::AdministrativeMetadataDS.from_xml(administrative_metadata_xml),
                      roleMetadata: instance_double(Dor::RoleMetadataDS, find_by_xpath: []))
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::APO.props(normalized_orig_fedora_apo_mock) }

    it 'roundtrip Fedora maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end
end

RSpec.describe 'Fedora APO identityMetadata <--> Cocina AdminPolicy Identification mappings' do
  # NOTE: tested in mapping/administrative/apo_administrative_spec.rb
  let(:default_access_props) do
    {
      access: 'dark',
      download: 'none'
    }
  end
  # NOTE: tested in mapping/administrative/apo_administrative_spec.rb
  let(:default_object_rights_xml) { "<rightsMetadata/>\n" }
  # NOTE: tested in mapping/descriptive/mods
  let(:description_props) do
    {
      title: [
        value: 'APO title'
      ],
      purl: "https://purl.stanford.edu/#{pid.split(':').last}",
      access: {
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      }
    }
  end

  context 'without adminPolicy, without referencesAgreement in identityMetadata.xml (in RELS_EXT)' do
    it_behaves_like 'APO Identification Fedora Cocina mapping' do
      let(:pid) { 'druid:zd878cf9993' }
      let(:label) { 'Fondo Lanciani' }
      let(:admin_policy_id) { 'druid:hv992ry2431' }
      let(:agreement_object_id) { 'druid:zh747vq3919' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{pid}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>adminPolicy</objectType>
            <otherId name="uuid">5844f566-282e-11e6-8872-005056a7ed61</otherId>
            <tag>Registered By : caster</tag>
            <tag>Remediated By : 5.10.0</tag>
          </identityMetadata>
        XML
      end

      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{pid}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>adminPolicy</objectType>
          </identityMetadata>
        XML
      end

      let(:cocina_props) do
        {
          externalIdentifier: pid,
          type: Cocina::Models::Vocab.admin_policy,
          label: label,
          version: 1,
          administrative: {
            hasAdminPolicy: admin_policy_id,
            referencesAgreement: agreement_object_id,
            defaultAccess: default_access_props,
            defaultObjectRights: default_object_rights_xml,
            roles: []
          },
          description: description_props
        }
      end
    end
  end

  context 'with agreementID, adminPolicy in identityMetadata.xml (Parker APO) (also in RELS_EXT)' do
    it_behaves_like 'APO Identification Fedora Cocina mapping' do
      let(:pid) { 'druid:bm077td6448' }
      let(:label) { 'Parker Manuscripts' }
      let(:admin_policy_id) { 'druid:nt592gh9590' }
      let(:agreement_object_id) { 'druid:tx617qp8040' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectLabel>#{label}</objectLabel>
            <adminPolicy>#{admin_policy_id}</adminPolicy>
            <agreementId>#{agreement_object_id}</agreementId>
            <objectType>adminPolicy</objectType>
            <otherId name="uuid">6abe4356-a584-bc4d-5256-aaaefdba2400</otherId>
            <objectId>#{pid}</objectId>
            <objectCreator>DOR</objectCreator>
            <tag>Remediated By : 5.11.0</tag>
          </identityMetadata>
        XML
      end

      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectLabel>#{label}</objectLabel>
            <objectType>adminPolicy</objectType>
            <objectId>#{pid}</objectId>
            <objectCreator>DOR</objectCreator>
          </identityMetadata>
        XML
      end

      let(:cocina_props) do
        {
          externalIdentifier: pid,
          type: Cocina::Models::Vocab.admin_policy,
          label: label,
          version: 1,
          administrative: {
            hasAdminPolicy: admin_policy_id,
            referencesAgreement: agreement_object_id,
            defaultAccess: default_access_props,
            defaultObjectRights: default_object_rights_xml,
            roles: []
          },
          description: description_props
        }
      end
    end
  end

  context 'with sourceId, without agreementId in identityMetadata.xml (CS Tech Reports) (agreementId in RELS_EXT)' do
    # it_behaves_like 'APO Identification Fedora Cocina mapping' do
    xit 'to be implemented: APO objects do need support sourceId' do
      let(:pid) { 'druid:bk068fh4950' }
      let(:label) { 'APO for Stanford University, Department of Computer Science, Technical Reports' }
      let(:admin_policy_id) { 'druid:zw306xn5593' }
      let(:agreement_object_id) { 'druid:mc322hh4254' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="Hydrus">adminPolicy-dhartwig-2013-06-10T18:11:42.520Z</sourceId>
            <objectId>#{pid}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>adminPolicy</objectType>
            <adminPolicy>#{admin_policy_id}</adminPolicy>
            <otherId name="uuid">341b275c-d1f9-11e2-ba42-0050569b3c6e</otherId>
            <tag>Project : Hydrus</tag>
            <tag>Remediated By : 4.6.6.2</tag>
          </identityMetadata>
        XML
      end

      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="Hydrus">adminPolicy-dhartwig-2013-06-10T18:11:42.520Z</sourceId>
            <objectId>#{pid}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>adminPolicy</objectType>
          </identityMetadata>
        XML
      end

      let(:cocina_props) do
        {
          externalIdentifier: pid,
          type: Cocina::Models::Vocab.admin_policy,
          label: label,
          version: 1,
          administrative: {
            hasAdminPolicy: admin_policy_id,
            referencesAgreement: agreement_object_id,
            defaultAccess: default_access_props,
            defaultObjectRights: default_object_rights_xml,
            roles: []
          },
          description: description_props
        }
      end
    end
  end
end
