# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'APO Fedora Cocina mapping' do
  # Required: admin_metadata_xml, default_object_rights_xml, role_metadata_xml, agreement_druid, cocina
  # Optional: roundtrip_admin_metadata_xml, roundtrip_default_object_rights_xml, roundtrip_role_metadata_xml

  let(:apo_druid) { 'apo_druid' }
  let(:apo_label) { 'apo_label' }
  let(:ur_apo_druid) { 'druid:hv992ry2431' }
  let(:orig_fedora_apo_mock) do
    # need to mock to avoid call to Solr
    instance_double(
      Dor::AdminPolicyObject,
      pid: apo_druid,
      label: apo_label,
      current_version: '1',
      admin_policy_object_id: ur_apo_druid,
      agreement_object_id: agreement_druid,
      administrativeMetadata: Dor::AdministrativeMetadataDS.from_xml(admin_metadata_xml),
      descMetadata: Dor::DescMetadataDS.from_xml('<mods/>'),
      # NOTE: DefaultObjectRights doesn't work with :from_xml
      defaultObjectRights: instance_double(Dor::DefaultObjectRightsDS, content: default_object_rights_xml),
      roleMetadata: Dor::RoleMetadataDS.from_xml(role_metadata_xml)
    )
  end
  let(:actual_cocina_props) { Cocina::FromFedora::APO.props(orig_fedora_apo_mock) }
  let(:expected_cocina_props) do
    {
      administrative: cocina.deep_dup,
      externalIdentifier: apo_druid,
      type: Cocina::Models::Vocab.admin_policy,
      label: apo_label,
      version: 1,
      description: {
        purl: "#{Settings.release.purl_base_url}/apo_druid",
        access: {
          digitalRepository: [
            {
              value: 'Stanford Digital Repository'
            }
          ]
        }
      }
    }
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina AdminPolicyAdministrative' do
      expect { Cocina::Models::AdminPolicyAdministrative.new(cocina) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina object props' do
      expect(actual_cocina_props).to be_deep_equal(expected_cocina_props)
    end
  end

  context 'when mapping from Cocina to Fedora' do
    let(:actual_cocina_apo_admin) { Cocina::Models::AdminPolicyAdministrative.new(cocina) }
    let(:roundtrip_fedora_apo) do
      Dor::AdminPolicyObject.new(pid: actual_cocina_props[:externalIdentifier],
                                 admin_policy_object_id: actual_cocina_apo_admin.hasAdminPolicy,
                                 agreement_object_id: actual_cocina_apo_admin.referencesAgreement,
                                 label: actual_cocina_props[:label])
    end

    describe 'Cocina::ToFedora::AdministrativeMetadata' do
      let(:actual_admin_metadata_xml) do
        Cocina::ToFedora::AdministrativeMetadata.write(roundtrip_fedora_apo.administrativeMetadata, actual_cocina_apo_admin)
        roundtrip_fedora_apo.administrativeMetadata.to_xml
      end

      it 'AdminPolicyAdministrative cocina model roundtrips to original administrativeMetadata.xml' do
        expect(actual_admin_metadata_xml).to be_equivalent_to(admin_metadata_xml)
      end
    end

    describe 'Cocina::ToFedora::DefaultRights' do
      let(:actual_default_rights_xml) do
        Cocina::ToFedora::DefaultRights.write(roundtrip_fedora_apo.defaultObjectRights, actual_cocina_apo_admin.defaultAccess) if actual_cocina_props[:administrative][:defaultAccess]
        roundtrip_fedora_apo.defaultObjectRights.to_xml
      end

      it 'AdminPolicyAdministrative cocina model roundtrips to original defaultObjectRights.xml' do
        expect(actual_default_rights_xml).to be_equivalent_to(default_object_rights_xml)
      end
    end

    describe 'Cocina::ToFedora::Roles' do
      let(:actual_role_xml) do
        Cocina::ToFedora::Roles.write(roundtrip_fedora_apo, actual_cocina_apo_admin.roles)
        roundtrip_fedora_apo.roleMetadata.to_xml
      end

      it 'AdminPolicyAdministrative cocina model roundtrips to original roleMetadata.xml' do
        expect(actual_role_xml).to be_equivalent_to(role_metadata_xml)
      end
    end

    describe 'object relations (RELS-EXT)' do
      let(:rels_ext_ng_xml) do
        ng = Nokogiri::XML(roundtrip_fedora_apo.datastreams['RELS-EXT'].to_rels_ext)
        ng.remove_namespaces!
      end

      it 'admin_policy_object_id roundtrips to original' do
        expect(rels_ext_ng_xml.xpath('//RDF/Description/isGovernedBy/@resource').text).to eq "info:fedora/#{cocina[:hasAdminPolicy]}"
      end

      it 'agreement_object_id roundtrips to original' do
        expect(rels_ext_ng_xml.xpath('//RDF/Description/referencesAgreement/@resource').text).to eq "info:fedora/#{agreement_druid}"
      end
    end
  end

  context 'when mapping from roundtrip Fedora to Cocina' do
    let(:my_roundtrip_admin_metadata_xml) do
      defined?(roundtrip_admin_metadata_xml) ? roundtrip_admin_metadata_xml : admin_metadata_xml
    end
    let(:my_roundtrip_default_object_rights_xml) do
      defined?(roundtrip_default_object_rights_xml) ? roundtrip_default_object_rights_xml : default_object_rights_xml
    end
    let(:my_roundtrip_role_metadata_xml) do
      defined?(roundtrip_role_metadata_xml) ? roundtrip_role_metadata_xml : role_metadata_xml
    end
    let(:roundtrip_fedora_apo_mock) do
      # need to mock to avoid call to Solr
      instance_double(
        Dor::AdminPolicyObject,
        pid: apo_druid,
        label: apo_label,
        current_version: '1',
        admin_policy_object_id: ur_apo_druid,
        agreement_object_id: agreement_druid,
        administrativeMetadata: Dor::AdministrativeMetadataDS.from_xml(my_roundtrip_admin_metadata_xml),
        descMetadata: Dor::DescMetadataDS.from_xml('<mods/>'),
        # NOTE: DefaultObjectRights doesn't work with :from_xml
        defaultObjectRights: instance_double(Dor::DefaultObjectRightsDS, content: my_roundtrip_default_object_rights_xml),
        roleMetadata: Dor::RoleMetadataDS.from_xml(my_roundtrip_role_metadata_xml)
      )
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::APO.props(roundtrip_fedora_apo_mock) }

    it 'roundtrip Fedora maps to expected Cocina object props' do
      expect(roundtrip_cocina_props).to be_deep_equal(expected_cocina_props)
    end
  end
end

RSpec.describe 'Fedora APO objects <--> cocina administrative mappings' do
  # NOTE:  some APO have descMetadata, contact, accessioning (WF) in the administrativeMetadata.  Ignoring for now
  describe 'world access, registration workflows, collection, single role' do
    # from bz845pv2292
    it_behaves_like 'APO Fedora Cocina mapping' do
      let(:admin_metadata_xml) do
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="goobiWF"/>
              <workflow id="registrationWF"/>
              <collection id="druid:ny719df8518"/>
            </registration>
          </administrativeMetadata>
        XML
      end
      let(:default_object_rights_xml) do
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
            <use>
              <human type="useAndReproduction">Blah blah</human>
            </use>
          </rightsMetadata>
        XML
      end
      let(:role_metadata_xml) do
        <<~XML
          <roleMetadata>
            <role type="dor-apo-manager">
              <group>
                <identifier type="workgroup">sdr:developer</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
      end
      let(:agreement_druid) { 'druid:yr951qr4199' }
      let(:cocina) do
        {
          defaultObjectRights: default_object_rights_xml,
          defaultAccess: {
            access: 'world',
            download: 'world',
            useAndReproductionStatement: 'Blah blah'
          },
          registrationWorkflow: [
            'goobiWF',
            'registrationWF'
          ],
          collectionsForRegistration: [
            'druid:ny719df8518'
          ],
          hasAdminPolicy: ur_apo_druid,
          referencesAgreement: agreement_druid,
          roles: [
            {
              name: 'dor-apo-manager',
              members: [
                {
                  type: 'workgroup',
                  identifier: 'sdr:developer'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'with disseminationWF, single registrationWF' do
    # based on wr005wn5739 - web archiving crawl APO
    it_behaves_like 'APO Fedora Cocina mapping' do
      let(:admin_metadata_xml) do
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="wasCrawlPreassemblyWF"/>
              <collection id="druid:bg567wp9439"/>
              <collection id="druid:bp350ns9783"/>
            </registration>
            <dissemination>
              <workflow id="wasDisseminationWF"/>
            </dissemination>
          </administrativeMetadata>
        XML
      end
      let(:default_object_rights_xml) do
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
      let(:role_metadata_xml) do
        <<~XML
          <roleMetadata>
            <role type="dor-apo-manager">
              <group>
                <identifier type="workgroup">sdr:developer</identifier>
              </group>
              <group>
                 <identifier type="workgroup">sdr:metadata-staff</identifier>
               </group>
               <group>
                 <identifier type="workgroup">sdr:was-staff</identifier>
               </group>
            </role>
          </roleMetadata>
        XML
      end
      let(:agreement_druid) { 'druid:wn586st0695' }
      let(:cocina) do
        {
          defaultObjectRights: default_object_rights_xml,
          defaultAccess: {
            access: 'world',
            download: 'world'
          },
          registrationWorkflow: [
            'wasCrawlPreassemblyWF'
          ],
          disseminationWorkflow: 'wasDisseminationWF',
          collectionsForRegistration: [
            'druid:bg567wp9439',
            'druid:bp350ns9783'
          ],
          hasAdminPolicy: ur_apo_druid,
          referencesAgreement: 'druid:wn586st0695',
          roles: [
            {
              name: 'dor-apo-manager',
              members: [
                {
                  type: 'workgroup',
                  identifier: 'sdr:developer'
                },
                {
                  type: 'workgroup',
                  identifier: 'sdr:metadata-staff'
                },
                {
                  type: 'workgroup',
                  identifier: 'sdr:was-staff'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'defaultObjectRights no-download, copyright, use' do
    # based on zd878cf9993
    it_behaves_like 'APO Fedora Cocina mapping' do
      let(:admin_metadata_xml) do
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
              <collection id="druid:ns135jb1096"/>
            </registration>
          </administrativeMetadata>
        XML
      end
      let(:default_object_rights_xml) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
            <copyright>
              <human>HOOMANS</human>
            </copyright>
            <use>
              <human type="useAndReproduction">Use at will.</human>
            </use>
          </rightsMetadata>
        XML
      end
      let(:role_metadata_xml) do
        <<~XML
          <roleMetadata>
            <role type="dor-apo-manager">
              <group>
                <identifier type="workgroup">sdr:developer</identifier>
              </group>
              <group>
                 <identifier type="workgroup">sdr:metadata-staff</identifier>
               </group>
            </role>
          </roleMetadata>
        XML
      end
      let(:agreement_druid) { 'druid:zh747vq3919' }
      let(:cocina) do
        {
          defaultObjectRights: default_object_rights_xml,
          defaultAccess: {
            access: 'world',
            download: 'none',
            copyright: 'HOOMANS',
            useAndReproductionStatement: 'Use at will.'
          },
          registrationWorkflow: [
            'registrationWF'
          ],
          collectionsForRegistration: [
            'druid:ns135jb1096'
          ],
          hasAdminPolicy: ur_apo_druid,
          referencesAgreement: 'druid:zh747vq3919',
          roles: [
            {
              name: 'dor-apo-manager',
              members: [
                {
                  type: 'workgroup',
                  identifier: 'sdr:developer'
                },
                {
                  type: 'workgroup',
                  identifier: 'sdr:metadata-staff'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'no collections, has license, roles with type sunetid' do
    # based on kt538yv1733 combined with default_obj_rights and roles from qv549bf9093
    # it_behaves_like 'APO Fedora Cocina mapping' do
    xit 'problems with empty name elements in role/person, with sunetid members, with license (roundtrips as license url)' do
      let(:admin_metadata_xml) do
        <<~XML
          <administrativeMetadata>
            <registration>
              <workflow id="registrationWF"/>
            </registration>
          </administrativeMetadata>
        XML
      end
      let(:default_object_rights_xml) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
            <use>
              <human type="useAndReproduction">Use at will.</human>
              <human type="creativeCommons">CC BY-NC Attribution-NonCommercial</human>
              <machine type="creativeCommons">by-nc</machine>
            </use>
          </rightsMetadata>
        XML
      end
      let(:role_metadata_xml) do
        <<~XML
          <roleMetadata>
            <role type="hydrus-collection-manager">
              <person>
                <identifier type="sunetid">dhartwig</identifier>
                <name/>
              </person>
              <person>
                <identifier type="sunetid">jschne</identifier>
                <name/>
              </person>
            </role>
            <role type="hydrus-collection-depositor">
              <person>
                <identifier type="sunetid">dhartwig</identifier>
                <name/>
              </person>
            </role>
            <role type="dor-apo-manager">
              <group>
                <identifier type="workgroup">sdr:psm-staff</identifier>
              </group>
              <group>
                <identifier type="workgroup">sdr:developer</identifier>
              </group>
            </role>
          </roleMetadata>
        XML
      end
      let(:agreement_druid) { 'druid:xf765cv5573' }
      let(:cocina) do
        {
          defaultObjectRights: default_object_rights_xml,
          defaultAccess: {
            access: 'world',
            download: 'none',
            license: 'https://creativecommons.org/licenses/by-nc/3.0/',
            useAndReproductionStatement: 'Use at will.'
          },
          registrationWorkflow: [
            'registrationWF'
          ],
          hasAdminPolicy: ur_apo_druid,
          referencesAgreement: agreement_druid,
          roles: [
            {
              name: 'hydrus-collection-manager',
              members: [
                {
                  type: 'sunetid',
                  identifier: 'dhartwig'
                },
                {
                  type: 'sunetid',
                  identifier: 'jschne'
                }
              ]
            },
            {
              name: 'hydrus-collection-depositor',
              members: [
                {
                  type: 'sunetid',
                  identifier: 'dhartwig'
                }
              ]
            },
            {
              name: 'dor-apo-manager',
              members: [
                {
                  type: 'workgroup',
                  identifier: 'sdr:psm-staff'
                },
                {
                  type: 'workgroup',
                  identifier: 'sdr:developer'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # TODO: add specs for additional data wrinkles surfaced via prod data roundtrip validation
  #   and from thinking about possible situations such as:
  # - defaultAccess:  readLocation; controlleddigitallending
  # - test without registrationWF ?
  # - test without admin policy (? - should throw error?)
  # - test without roles ?
end
