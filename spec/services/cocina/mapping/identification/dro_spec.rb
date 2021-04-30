# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'DRO Identification Fedora Cocina mapping' do
  # Required: item_id, label, admin_policy_id, collection_ids, identity_metadata_xml, cocina_props
  # Optional: catkey, source_id_source, source_id, other_id_name, other_id, roundtrip_identity_metadata_xml

  # Normalization notes for later:
  #  otherId of type uuid -> normalize out (keep catkey, barcode ...)  shelfseq, callseq? dissertationid (YES?)?,
  #  tags (non-release) -> normalize out
  #  adminPolicy -> normalize out (we use RELS-EXT)
  #  sourceId -> we need to KEEP - every item should have a sourceId, as should agreements
  #  releaseTag -> we need to KEEP
  #  displayType -> normalize out
  #  missing collections OK -- don't produce cocina with nil druid for collection
  #  citationTitle, citationCreator -> normalize out
  #  agreementId?  -> normalize out -> should only be for APOs
  # multiple collections -> ok
  #  objectAdminClass -> normalize out

  let(:namespaced_source_id) { defined?(source_id) && defined?(source_id_source) ? "#{source_id_source}:#{source_id}" : nil }
  let(:namespaced_other_ids) do
    other_id_nodes = Nokogiri::XML(identity_metadata_xml).xpath('//identityMetadata/otherId')
    other_id_nodes.map { |other_id_node| "#{other_id_node['name']}:#{other_id_node.text}" }
  end
  let(:mods_xml) do
    <<~XML
      <mods #{MODS_ATTRIBUTES}>
        <titleInfo>
          <title>item title</title>
        </titleInfo>
      </mods>
    XML
  end
  # using a mock rather than every example having all relevant datastreams
  let(:fedora_item_mock) do
    instance_double(Dor::Item,
                    pid: item_id,
                    id: item_id, # see app/services/cocina/from_fedora/administrative.rb:22
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
                    geoMetadata: Dor::GeoMetadataDS.new,
                    contentMetadata: Dor::ContentMetadataDS.new,
                    rightsMetadata: Dor::RightsMetadataDS.new)
  end
  let(:mapped_cocina_props) { Cocina::FromFedora::DRO.props(fedora_item_mock) }
  let(:roundtrip_identity_md_xml) { defined?(roundtrip_identity_metadata_xml) ? roundtrip_identity_metadata_xml : identity_metadata_xml }
  let(:roundtrip_fedora_item) do
    cocina_dro = Cocina::Models::DRO.new(mapped_cocina_props)
    fedora_item = Dor::Item.new(pid: cocina_dro.externalIdentifier,
                                source_id: cocina_dro.identification.sourceId,
                                catkey: Cocina::ObjectCreator.new.send(:catkey_for, cocina_dro),
                                label: Cocina::ObjectCreator.new.send(:truncate_label, cocina_dro.label))
    Cocina::ToFedora::Identity.apply(fedora_item, label: cocina_dro.label, agreement_id: cocina_dro.structural&.hasAgreement)
    fedora_item.identityMetadata.barcode = cocina_dro.identification.barcode
    fedora_item
  end
  let(:mapped_roundtrip_identity_xml) do
    Cocina::ToFedora::Identity.apply(roundtrip_fedora_item, label: mapped_cocina_props[:label])
    roundtrip_fedora_item.identityMetadata.to_xml
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
    let(:roundtrip_fedora_item_mock) do
      instance_double(Dor::Item,
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
                      geoMetadata: Dor::GeoMetadataDS.new,
                      contentMetadata: Dor::ContentMetadataDS.new,
                      rightsMetadata: Dor::RightsMetadataDS.new)
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::DRO.props(roundtrip_fedora_item_mock) }

    before do
      allow(roundtrip_fedora_item_mock).to receive(:is_a?).with(Dor::Agreement).and_return(false)
      allow(roundtrip_fedora_item_mock).to receive(:is_a?).with(Dor::Item).and_return(true)
    end

    it 'roundtrip Fedora maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end
end

RSpec.describe 'Fedora Item identityMetadata <--> Cocina DRO Identification mappings' do
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
        value: 'item title'
      ],
      purl: "http://purl.stanford.edu/#{item_id.split(':').last}",
      access: {
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      }
    }
  end

  context 'with simple example (even tho geo)' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bb053zc5914' }
      let(:label) { 'L15_1655E_1008N' }
      let(:admin_policy_id) { 'druid:bc198wr8388' } # from RELS-EXT
      let(:collection_ids) { ['druid:hh178mz6257'] } # from RELS-EXT
      let(:source_id_source) { 'branner' }
      let(:source_id) { 'drainagecanalsSEAsia_L15_1655E_1008N.tif' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with simple example with catkey and no collection' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bb010dx6027' }
      let(:label) { 'The rite of spring' }
      let(:catkey) { '8501137' }
      let(:admin_policy_id) { 'druid:bz845pv2292' } # from RELS-EXT
      let(:collection_ids) { [] } # not in RELS-EXT
      let(:source_id_source) { 'sul' }
      let(:source_id) { 'naxos_nac_8.557501' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <objectLabel>#{label}</objectLabel>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}",
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
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

  context 'with empty otherId with name' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bb274jy1491' }
      let(:label) { 'Cashews, Harvested Area Data Quality, 1997-2003' }
      let(:admin_policy_id) { 'druid:mh095yb8404' } # from RELS-EXT
      let(:collection_ids) { ['druid:tz390fn8810'] } # from RELS-EXT
      let(:source_id_source) { 'branner' }
      let(:source_id) { 'EStat_cashew_DataQuality_HarvestedArea.tif' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <otherId name="label"/>
            <otherId name="uuid">bc466ea0-e358-11e7-917d-0050569b2d90</otherId>
            <tag>Process : Content Type : File</tag>
            <tag>Registered By : kdurante</tag>
            <tag>Dataset : GIS</tag>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with googlebooks item (with release tags)' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:bb000jd2736' }
      let(:label) { 'The life of Goethe' }
      let(:catkey) { '2003938' }
      let(:admin_policy_id) { 'druid:dx569vq3421' } # from RELS-EXT
      let(:collection_ids) { ['druid:yh583fk3400'] } # from RELS-EXT
      let(:source_id_source) { 'googlebooks' }
      let(:source_id) { 'stanford_36105010362304' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <objectLabel>#{label}</objectLabel>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectType>item</objectType>
            <release what="self" to="Searchworks" who="cspitzer" when="2021-02-18T21:46:35Z">true</release>
            <release what="self" to="Searchworks" who="bergeraj" when="2021-03-05T08:42:18Z">false</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}",
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'cspitzer',
                what: 'self',
                date: '2021-02-18T21:46:35Z',
                to: 'Searchworks',
                release: true
              },
              {
                who: 'bergeraj',
                what: 'self',
                date: '2021-03-05T08:42:18Z',
                to: 'Searchworks',
                release: false
              }
            ]
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with project phoenix item; no collection, has agreement, has barcode' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bb005bg5914' }
      let(:label) { 'Google Scanned Book, barcode 36105014928126' }
      let(:catkey) { '405984' }
      let(:barcode) { '36105014928126' }
      let(:admin_policy_id) { 'druid:rp029yq2361' } # from RELS-EXT
      let(:collection_ids) { [] } # not in RELS-EXT
      let(:source_id_source) { 'google' }
      let(:source_id) { 'STANFORD_36105014928126' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectAdminClass>GoogleBooks</objectAdminClass>
            <objectLabel>#{label}</objectLabel>
            <objectCreator>DOR</objectCreator>
            <citationTitle>Proceedings</citationTitle>
            <citationCreator>Somersetshire Archaeological and Natural History Society</citationCreator>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="shelfseq">DA 000670 .S49 S55 V.000045-000046 001899-001900</otherId>
            <otherId name="barcode">#{barcode}</otherId>
            <otherId name="callseq">29</otherId>
            <otherId name="uuid">6d408a7d-46c1-446c-ad4c-e5b0633830eb</otherId>
            <agreementId>druid:zn292gq7284</agreementId>
            <tag>Book : Multi-volume work</tag>
            <tag>Google Book : GBS VIEW_FULL</tag>
            <tag>Book : Non-US pre-1891</tag>
            <tag>Google Book : Scan source STANFORD</tag>
            <tag>Remediated By : 3.6.2</tag>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel>#{label}</objectLabel>
            <objectCreator>DOR</objectCreator>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="barcode">#{barcode}</otherId>
            <agreementId>druid:zn292gq7284</agreementId>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            barcode: barcode,
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ],
            sourceId: 'google:STANFORD_36105014928126'
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            hasAgreement: 'druid:zn292gq7284'
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with early ETD, empty objectLabel, no sourceID ... (with release tags)' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:px901zd6069' }
      let(:label) { '' }
      let(:catkey) { '8537171' }
      let(:admin_policy_id) { 'druid:bx911tp9024' } # from RELS-EXT
      let(:collection_ids) { [] } # not in RELS-EXT
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <citationTitle>The design and implementation of dynamic information flow tracking systems for software security: 2009, c2010</citationTitle>
            <citationCreator>Dalton, Michael</citationCreator>
            <otherId name="dissertationid">0000000001</otherId>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="uuid">aefeb8c0-632e-11e1-b86c-0800200c9a66</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <objectAdminClass>ETDs</objectAdminClass>
            <tag>ETD : Term 1102</tag>
            <tag>ETD : Dissertation</tag>
            <release to="Searchworks" what="self" when="2017-02-07T10:45:17Z" who="blalbrit">true</release>
            <tag>Remediated By : 5.11.0</tag>
          </identityMetadata>
        XML
      end
      # NOTE: dissertationid becomes sourceId
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <sourceId source="dissertationid">0000000001</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <release to="Searchworks" what="self" when="2017-02-07T10:45:17Z" who="blalbrit">true</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: '',
          version: 1,
          identification: {
            sourceId: 'dissertationid:0000000001',
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'blalbrit',
                what: 'self',
                date: '2017-02-07T10:45:17Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            hasAgreement: 'druid:ct692vv3660'
            # isMemberOf: [
            #   nil
            # ]
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with ETD with 2 catkeys' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: what to do with 2 catkeys; release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:zw844wz5427' }
      let(:label) { '' }
      let(:catkey) { '8652337' }
      let(:admin_policy_id) { 'druid:bx911tp9024' } # from RELS-EXT
      let(:collection_ids) { [] } # not in RELS-EXT
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <citationTitle>Multiphoton interactions with transparent tissues: applications to imaging and surgery</citationTitle>
            <citationCreator>Toytman, Ilya</citationCreator>
            <otherId name="dissertationid">0000000296</otherId>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="uuid">bb8e629e-6328-11e1-9378-022c4a816c60</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <tag>ETD : Term 1106</tag>
            <tag>ETD : Dissertation</tag>
            <tag>Remediated By : 4.20.1</tag>
            <release to="Searchworks" who="blalbrit" what="self" when="2017-02-07T11:07:41Z">true</release>
            <release to="Searchworks" who="blalbrit" what="self" when="2017-02-07T15:15:41Z">true</release>
            <otherId name="catkey">12303517</otherId>
            <release to="Searchworks" who="cebraj" what="self" when="2018-05-14T23:26:59Z">true</release>
          </identityMetadata>
        XML
      end
      # NOTE: dissertationid becomes sourceId
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <sourceId source="dissertationid">0000000296</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <release to="Searchworks" who="blalbrit" what="self" when="2017-02-07T11:07:41Z">true</release>
            <release to="Searchworks" who="blalbrit" what="self" when="2017-02-07T15:15:41Z">true</release>
            <otherId name="catkey">12303517</otherId>
            <release to="Searchworks" who="cebraj" what="self" when="2018-05-14T23:26:59Z">true</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: '',
          version: 1,
          identification: {
            sourceId: 'dissertationid:0000000296',
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'blalbrit',
                what: 'self',
                date: '2017-02-07T11:07:41Z',
                to: 'Searchworks',
                release: true
              },
              {
                who: 'blalbrit',
                what: 'self',
                date: '2017-02-07T15:15:41Z',
                to: 'Searchworks',
                release: true
              },
              {
                who: 'cebraj',
                what: 'self',
                date: '2018-05-14T23:26:59Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            hasAgreement: 'druid:ct692vv3660'
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with ETD with empty citation elements' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:mr401cc4586' }
      let(:label) { '' }
      let(:catkey) { '10327542' }
      let(:admin_policy_id) { 'druid:bx911tp9024' } # from RELS-EXT
      let(:collection_ids) { [] } # not in RELS-EXT
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <citationTitle/>
            <citationCreator/>
            <otherId name="dissertationid">0000002905</otherId>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="uuid">f8493238-61a8-11e3-922e-0050569b52d5</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <objectAdminClass>ETDs</objectAdminClass>
            <tag>ETD : Dissertation</tag>
            <tag>Remediated By : 4.17.1</tag>
            <release to="Searchworks" what="self" when="2017-02-07T10:01:59Z" who="blalbrit">true</release>
          </identityMetadata>
        XML
      end
      # NOTE: dissertationid becomes sourceId
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <sourceId source="dissertationid">0000002905</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <release to="Searchworks" what="self" when="2017-02-07T10:01:59Z" who="blalbrit">true</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: '',
          version: 1,
          identification: {
            sourceId: 'dissertationid:0000002905',
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'blalbrit',
                what: 'self',
                date: '2017-02-07T10:01:59Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            hasAgreement: 'druid:ct692vv3660'
            # isMemberOf: [
            #   nil
            # ]
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with ETD without citation elements' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:xs522rn2310' }
      let(:label) { '' }
      let(:catkey) { '12684953' }
      let(:admin_policy_id) { 'druid:bx911tp9024' } # from RELS-EXT
      let(:collection_ids) { [] } # not in RELS-EXT
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <otherId name="dissertationid">0000006152</otherId>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="uuid">2f3dc52e-7487-11e8-ae3a-005056a7d1e9</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <objectAdminClass>ETDs</objectAdminClass>
            <tag>ETD : Dissertation</tag>
            <release to="Searchworks" what="self" when="2018-10-19T17:37:18Z" who="arcadia">true</release>
          </identityMetadata>
        XML
      end
      # NOTE: dissertationid becomes sourceId
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel/>
            <objectCreator>DOR</objectCreator>
            <sourceId source="dissertationid">0000006152</sourceId>
            <otherId name="catkey">#{catkey}</otherId>
            <agreementId>druid:ct692vv3660</agreementId>
            <release to="Searchworks" what="self" when="2018-10-19T17:37:18Z" who="arcadia">true</release>
          </identityMetadata>
        XML
      end

      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: '',
          version: 1,
          identification: {
            sourceId: 'dissertationid:0000006152',
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'arcadia',
                what: 'self',
                date: '2018-10-19T17:37:18Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            hasAgreement: 'druid:ct692vv3660'
            # isMemberOf: [
            #   nil
            # ]
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with Bassi-Verati item' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bn012fy8818' }
      let(:label) { '"Al marito impareggiabile della signora Laura Maria Catterina Bassi", Sonetto di M.D.G.L., s.d.' }
      let(:admin_policy_id) { 'druid:wq307yk9043' } # from RELS-EXT
      let(:collection_ids) { ['druid:nx585yw5390'] } # from RELS-EXT
      let(:source_id_source) { 'Archiginnasio' }
      let(:source_id) { 'Bassi_Box6_Folder6_Item2' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <adminPolicy>#{admin_policy_id}</adminPolicy>
            <otherId name="uuid">037df272-d787-11e1-9eae-0016034322e2</otherId>
            <tag>Project : Bassi Veratti</tag>
            <tag>Registered By : mgolson</tag>
            <tag>Remediated By : 3.17.13</tag>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with SPEC (special collections) item' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:fn010kg7712' }
      let(:label) { 'Mainichi Shinbun, Japanese, shichigatsu 21' }
      let(:admin_policy_id) { 'druid:ww057vk7675' } # from RELS-EXT
      let(:collection_ids) { ['druid:hh178mz6257'] } # from RELS-EXT
      let(:source_id_source) { 'sul' }
      let(:source_id) { 'ARmoonlanding_i4' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <adminPolicy>#{admin_policy_id}</adminPolicy>
            <otherId name="uuid">da9c0b9a-dfe8-11e1-a037-0016034322e2</otherId>
            <tag>Project : Digitization Request</tag>
            <tag>JIRA : DIGREQ-427</tag>
            <tag>DPG : Digitization Request</tag>
            <tag>DPG : Access Services</tag>
            <tag>DPG : Purnell</tag>
            <tag>Registered By : astrids</tag>
            <tag>Remediated By : 3.25.3</tag>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with source id namespace trailing space, id has multiple leading spaces' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bb077vq3166' }
      let(:label) { '16152_24A_SM' }
      let(:admin_policy_id) { 'druid:qp256sh2346' } # from RELS-EXT
      let(:collection_ids) { ['druid:vx796zh5418'] } # from RELS-EXT
      let(:source_id_source) { 'sul ' }
      let(:source_id) { '  16152_24A_SM' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <adminPolicy>druid:qp256sh2346</adminPolicy>
            <otherId name="label"/>
            <otherId name="uuid">f8621178-2317-11e4-9677-0050569b3c3c</otherId>
            <tag>Process : Content Type : Image</tag>
            <tag>Project : Menuez</tag>
            <tag>Project : Menuez : Batch2</tag>
            <tag>Registered By : blalbrit</tag>
            <tag>Remediated By : 4.6.6.2</tag>
          </identityMetadata>
        XML
      end
      # NOTE: source and source_id values stripped of leading and trailing whitespace
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source.strip}">#{source_id.strip}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source.strip}:#{source_id.strip}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with displayType (Hydrus item)' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:gj077jb7878' }
      let(:label) { 'Open Science Perspective' }
      let(:admin_policy_id) { 'druid:sn486kf1487' } # from RELS-EXT
      let(:collection_ids) { ['druid:ck552zg2217'] } # from RELS-EXT
      let(:source_id_source) { 'Hydrus' }
      let(:source_id) { 'item-amyhodge-2013-12-19T23:04:19.236Z' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <adminPolicy>#{admin_policy_id}</adminPolicy>
            <otherId name="uuid">e44a8574-6901-11e3-a6d0-0050569b3c6e</otherId>
            <tag>Project : Hydrus</tag>
            <tag>Remediated By : 3.25.3</tag>
            <displayType>file</displayType>
            <release displayType="file" release="true" to="Searchworks" what="self" when="2015-10-25T21:29:13Z" who="blalbrit">true</release>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <release displayType="file" release="true" to="Searchworks" what="self" when="2015-10-25T21:29:13Z" who="blalbrit">true</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'blalbrit',
                what: 'self',
                date: '2015-10-25T21:29:13Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with web archive seed (old)' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:bj731rx4986' }
      let(:label) { 'http://nippongenkikai.jp/' }
      let(:admin_policy_id) { 'druid:xt299pt7593' } # from RELS-EXT
      let(:collection_ids) { ['druid:sr233xh9483'] } # from RELS-EXT
      let(:source_id_source) { 'sul' }
      let(:source_id) { 'ARCHIVEIT-EAL-8001-nippongenkikai.jp/' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <otherId name="uuid">49bc073a-e1e8-11e7-95c6-005056a7edb9</otherId>
            <tag>webarchive : seed</tag>
            <release to="Searchworks" who="reganmk" what="self" when="2018-05-21T21:40:51Z">true</release>
            <release to="Searchworks" who="cebraj" what="self" when="2018-07-19T21:35:44Z">true</release>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <release to="Searchworks" who="reganmk" what="self" when="2018-05-21T21:40:51Z">true</release>
            <release to="Searchworks" who="cebraj" what="self" when="2018-07-19T21:35:44Z">true</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'reganmk',
                what: 'self',
                date: '2018-05-21T21:40:51Z',
                to: 'Searchworks',
                release: true
              },
              {
                who: 'cebraj',
                what: 'self',
                date: '2018-07-19T21:35:44Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with web archive seed (new)' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:bb143kr5856' }
      let(:label) { 'http://cheme.stanford.edu/' }
      let(:admin_policy_id) { 'druid:xt299pt7593' } # from RELS-EXT
      let(:collection_ids) { ['druid:xs048zp7815'] } # from RELS-EXT
      let(:source_id_source) { 'sul' }
      let(:source_id) { 'ARCHIVEIT-UA-5591-http://cheme.stanford.edu' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <release what="self" to="Searchworks" who="pchan3" when="2020-10-28T23:53:05Z">false</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'pchan3',
                what: 'self',
                date: '2020-10-28T23:53:05Z',
                to: 'Searchworks',
                release: false
              }
            ]
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with 2 collections and objectLabel with xml encoding' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: do not double XML escape ampersands in objectLabel' do
      let(:item_id) { 'druid:bb001zc5754' }
      let(:label) { 'French Grand Prix &amp; 12 Hour Rheims 7/4/1954' }
      let(:admin_policy_id) { 'druid:qv648vd4392' } # from RELS-EXT
      let(:collection_ids) { ['druid:nt028fd5773', 'druid:wy149zp6932'] } # from RELS-EXT
      let(:source_id_source) { 'Revs' }
      let(:source_id) { '2006-001PHIL-1954-b1_29.1_0021' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <adminPolicy>#{admin_policy_id}</adminPolicy>
            <otherId name="uuid">b9af2444-2525-11e2-a4c7-0050569b52d5</otherId>
            <tag>Project : Revs</tag>
            <tag>Remediated By : 4.23.0</tag>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: [
              'druid:nt028fd5773',
              'druid:wy149zp6932'
            ]
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with objectAdminClass (EEMS) and same catkey twice, no collection' do
    # it_behaves_like 'DRO Identification Fedora Cocina mapping' do
    xit 'to be implemented: release tags need to roundtrip back into identityMetadata.xml' do
      let(:item_id) { 'druid:bb029vy9696' }
      let(:label) { 'EEMs: Finite State Continuous-Time Markov Decision Processes with Applications to a Class of Optimization Problems in Queueing Theory' }
      let(:catkey) { '10208128' }
      let(:admin_policy_id) { 'druid:jj305hm5259' } # from RELS-EXT
      let(:collection_ids) { [] } # none in RELS-EXT
      let(:source_id_source) { 'eems' }
      let(:source_id) { 'eems_src_00001' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel>#{label}</objectLabel>
            <objectAdminClass>EEMs</objectAdminClass>
            <agreementId>druid:fn200hb6598</agreementId>
            <tag>EEM : 1.0</tag>
            <otherId name="catkey">#{catkey}</otherId>
            <tag>Remediated By : 5.8.1</tag>
            <release to="Searchworks" what="self" when="2016-11-22T19:21:08Z" who="blalbrit">true</release>
            <release to="Searchworks" what="self" when="2016-11-22T21:35:46Z" who="blalbrit">true</release>
            <otherId name="catkey">#{catkey}</otherId>
            <release to="Searchworks" what="self" when="2018-05-15T00:31:17Z" who="cebraj">true</release>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
          </identityMetadata>
        XML
      end
      # NOTE: missing objectCreator added
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{item_id}</objectId>
            <objectType>item</objectType>
            <objectLabel>#{label}</objectLabel>
            <objectCreator>DOR</objectCreator>
            <agreementId>druid:fn200hb6598</agreementId>
            <otherId name="catkey">#{catkey}</otherId>
            <release to="Searchworks" what="self" when="2016-11-22T19:21:08Z" who="blalbrit">true</release>
            <release to="Searchworks" what="self" when="2016-11-22T21:35:46Z" who="blalbrit">true</release>
            <release to="Searchworks" what="self" when="2018-05-15T00:31:17Z" who="cebraj">true</release>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}",
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                who: 'blalbrit',
                what: 'self',
                date: '2016-11-22T19:21:08Z',
                to: 'Searchworks',
                release: true
              },
              {
                who: 'blalbrit',
                what: 'self',
                date: '2016-11-22T21:35:46Z',
                to: 'Searchworks',
                release: true
              },
              {
                who: 'cebraj',
                what: 'self',
                date: '2018-05-15T00:31:17Z',
                to: 'Searchworks',
                release: true
              }
            ]
          },
          structural: {
            hasAgreement: 'druid:fn200hb6598'
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end

  context 'with &#x escaped chars in objectLabel (FRDA)' do
    it_behaves_like 'DRO Identification Fedora Cocina mapping' do
      let(:item_id) { 'druid:bb016nw8128' }
      let(:label) { 'E&#x301;ve&#x301;nement du 19 fevrier 1790' }
      let(:admin_policy_id) { 'druid:ht275vw4351' } # from RELS-EXT
      let(:collection_ids) { ['druid:jh957jy1101'] } # from RELS-EXT
      let(:source_id_source) { 'French Revolution Digital Archive' }
      let(:source_id) { 'BNF:06944651' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>item</objectType>
            <adminPolicy>druid:ht275vw4351</adminPolicy>
            <otherId name="uuid">c2c9b4f6-4bac-11e2-b8ce-0050569b52d5</otherId>
            <tag>Project : French Revolution Digital Archive</tag>
            <tag>Remediated By : 3.25.3</tag>
          </identityMetadata>
        XML
      end
      # NOTE: label: xml escapes ampersands in unicode hex characters
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <sourceId source="#{source_id_source}">#{source_id}</sourceId>
            <objectId>#{item_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>E&amp;#x301;ve&amp;#x301;nement du 19 fevrier 1790</objectLabel>
            <objectType>item</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: item_id,
          type: Cocina::Models::Vocab.object,
          label: label,
          version: 1,
          identification: {
            sourceId: "#{source_id_source}:#{source_id}"
          },
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          structural: {
            isMemberOf: collection_ids
          },
          access: access_props,
          description: description_props
        }
      end
    end
  end
end
