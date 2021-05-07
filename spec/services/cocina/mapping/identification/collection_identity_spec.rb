# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'Collection Identification Fedora Cocina mapping' do
  # Required: collection_id, label, admin_policy_id, identity_metadata_xml, cocina_props
  # Optional: catkey, source_id_source, source_id, other_id_name, other_id, roundtrip_identity_metadata_xml

  # Normalization notes for later:
  #  otherId of type uuid -> normalize out (keep catkey, barcode ...)
  #  tags -> normalize out
  #  agreementId, adminPolicy -> normalize out (we use RELS-EXT)
  #  sourceId -> we need to KEEP
  #  releaseTag -> we need to KEEP
  #  multiple objectType -> can drop set type and keep collection type
  #  displayType -> normalize out

  let(:namespaced_source_id) { defined?(source_id) && defined?(source_id_source) ? "#{source_id_source}:#{source_id}" : nil }
  let(:namespaced_other_id) { defined?(other_id) && defined?(other_id_name) ? "#{other_id_name}:#{other_id}" : nil }
  let(:mods_xml) do
    <<~XML
      <mods #{MODS_ATTRIBUTES}>
        <titleInfo>
          <title>collection title</title>
        </titleInfo>
      </mods>
    XML
  end
  # NOTE: rightsMetadata mappings are tested elsewhere
  let(:rights_metadata_xml) do
    <<~XML
      <rightsMetadata/>
    XML
  end
  let(:fedora_collection_mock) do
    instance_double(Dor::Collection,
                    pid: collection_id,
                    id: collection_id, # see app/services/cocina/from_fedora/administrative.rb:22
                    label: label,
                    current_version: '1',
                    admin_policy_object_id: defined?(admin_policy_id) ? admin_policy_id : nil,
                    catkey: defined?(catkey) ? catkey : nil,
                    source_id: namespaced_source_id,
                    otherId: [namespaced_other_id],
                    identityMetadata: Dor::IdentityMetadataDS.from_xml(identity_metadata_xml),
                    descMetadata: Dor::DescMetadataDS.from_xml(mods_xml),
                    rightsMetadata: Dor::RightsMetadataDS.from_xml(rights_metadata_xml))
  end
  let(:mapped_cocina_props) { Cocina::FromFedora::Collection.props(fedora_collection_mock) }
  let(:normalized_orig_identity_xml) do
    # the starting identityMetadata.xml is normalized to address discrepancies found against identityMetadata roundtripped
    #  from data store (Fedora) and back, per Andrew's specifications.
    #  E.g., <adminPolicy> is removed as that information will not be carried over and is retrieved from RELS-EXT
    Cocina::Normalizers::IdentityNormalizer.normalize(identity_ng_xml: Nokogiri::XML(identity_metadata_xml)).to_xml
  end
  let(:roundtrip_identity_md_xml) { defined?(roundtrip_identity_metadata_xml) ? roundtrip_identity_metadata_xml : identity_metadata_xml }
  let(:mapped_cocina_collection) { Cocina::Models::Collection.new(mapped_cocina_props) }
  let(:mapped_fedora_collection) do
    Dor::Collection.new(pid: mapped_cocina_collection.externalIdentifier,
                        admin_policy_object_id: mapped_cocina_collection.administrative.hasAdminPolicy,
                        source_id: mapped_cocina_collection.identification&.sourceId,
                        catkey: Cocina::ObjectCreator.new.send(:catkey_for, mapped_cocina_collection),
                        label: Cocina::ObjectCreator.new.send(:truncate_label, mapped_cocina_collection.label))
  end
  let(:mapped_roundtrip_identity_xml) do
    Cocina::ToFedora::Identity.initialize_identity(mapped_fedora_collection)
    Cocina::ToFedora::Identity.apply_label(mapped_fedora_collection, label: mapped_cocina_collection.label)
    Cocina::ToFedora::Identity.apply_release_tags(mapped_fedora_collection, release_tags: mapped_cocina_collection.administrative.releaseTags)
    mapped_fedora_collection.identityMetadata.to_xml
  end

  before do
    allow(fedora_collection_mock).to receive(:is_a?).with(Dor::Collection).and_return(true)
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina Descriptive model' do
      expect { Cocina::Models::Collection.new(cocina_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_cocina_props).to be_deep_equal(cocina_props)
    end
  end

  context 'when mapping from Cocina to (roundtrip) Fedora' do
    it 'identityMetadata roundtrips thru cocina model to expected roundtrip identityMetadata.xml' do
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
    let(:roundtrip_fedora_collection_mock) do
      instance_double(Dor::Collection,
                      pid: mapped_cocina_props[:externalIdentifier],
                      id: mapped_cocina_props[:externalIdentifier], # see app/services/cocina/from_fedora/administrative.rb:22
                      label: mapped_cocina_props[:label],
                      current_version: '1',
                      admin_policy_object_id: mapped_cocina_props[:administrative][:hasAdminPolicy],
                      catkey: roundtrip_catkey,
                      source_id: mapped_cocina_props[:identification][:sourceId],
                      identityMetadata: Dor::IdentityMetadataDS.from_xml(mapped_roundtrip_identity_xml),
                      descMetadata: Dor::DescMetadataDS.from_xml(mods_xml),
                      rightsMetadata: Dor::RightsMetadataDS.from_xml(rights_metadata_xml))
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::Collection.props(roundtrip_fedora_collection_mock) }

    before do
      allow(roundtrip_fedora_collection_mock).to receive(:is_a?).with(Dor::Collection).and_return(true)
    end

    it 'roundtrip Fedora maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end

  context 'when mapping from normalized orig Fedora identity_metadata_xml to (roundtrip) Cocina' do
    # using a mock rather than every example having all relevant datastreams
    let(:normalized_orig_fedora_collection_mock) do
      instance_double(Dor::Collection,
                      pid: collection_id,
                      id: collection_id, # see app/services/cocina/from_fedora/administrative.rb:22
                      label: label,
                      current_version: '1',
                      admin_policy_object_id: defined?(admin_policy_id) ? admin_policy_id : nil,
                      catkey: defined?(catkey) ? catkey : nil,
                      source_id: namespaced_source_id,
                      otherId: [namespaced_other_id],
                      identityMetadata: Dor::IdentityMetadataDS.from_xml(normalized_orig_identity_xml),
                      descMetadata: Dor::DescMetadataDS.from_xml(mods_xml),
                      rightsMetadata: Dor::RightsMetadataDS.from_xml(rights_metadata_xml))
    end
    let(:roundtrip_cocina_props) { Cocina::FromFedora::Collection.props(normalized_orig_fedora_collection_mock) }

    before do
      allow(normalized_orig_fedora_collection_mock).to receive(:is_a?).with(Dor::Collection).and_return(true)
    end

    it 'normalized orig Fedora identity_metadata_xml maps to expected Cocina props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_props)
    end
  end
end

RSpec.describe 'Fedora Collection identityMetadata <--> Cocina Collection Identification mappings' do
  # NOTE: access tested in mapping/access/collection_access_spec.rb
  let(:access_props) do
    {
      access: 'dark'
    }
  end
  # NOTE: description tested in mapping/descriptive/mods
  let(:description_props) do
    {
      title: [
        value: 'collection title'
      ],
      purl: "http://purl.stanford.edu/#{collection_id.split(':').last}",
      access: {
        digitalRepository: [
          {
            value: 'Stanford Digital Repository'
          }
        ]
      }
    }
  end

  describe 'Hydrus collection' do
    context 'with release tags' do
      it_behaves_like 'Collection Identification Fedora Cocina mapping' do
        let(:collection_id) { 'druid:ds247vz0452' }
        let(:label) { 'Undergraduate Theses, Department of Physics' }
        let(:admin_policy_id) { 'druid:dx569vq3421' } # from RELS-EXT
        let(:source_id_source) { 'Hydrus' }
        let(:source_id) { 'collection-hfrost-2013-02-21T21:28:38.119Z' }
        let(:other_id_name) { 'uuid' }
        let(:other_id) { 'a7b70ac8-7c6d-11e2-9a96-0050569b3c6e' }
        let(:identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
              <adminPolicy>#{admin_policy_id}</adminPolicy>
              <otherId name="#{other_id_name}">#{other_id}</otherId>
              <tag>Project : Hydrus</tag>
              <objectType>set</objectType>
              <release displayType="file" release="true" to="Searchworks" what="self" when="2015-07-27T18:43:32Z" who="lauraw15">true</release>
              <release displayType="file" release="true" to="Searchworks" what="self" when="2015-10-25T21:12:42Z" who="blalbrit">true</release>
              <tag>Remediated By : 4.22.3</tag>
              <displayType>file</displayType>
              <release displayType="file" release="false" to="Searchworks" what="self" when="2016-07-15T23:44:01Z" who="blalbrit">false</release>
            </identityMetadata>
          XML
        end
        let(:roundtrip_identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
              <release to="Searchworks" what="self" when="2015-07-27T18:43:32Z" who="lauraw15">true</release>
              <release to="Searchworks" what="self" when="2015-10-25T21:12:42Z" who="blalbrit">true</release>
              <release to="Searchworks" what="self" when="2016-07-15T23:44:01Z" who="blalbrit">false</release>
            </identityMetadata>
          XML
        end
        let(:cocina_props) do
          {
            externalIdentifier: collection_id,
            type: Cocina::Models::Vocab.collection,
            label: label,
            version: 1,
            identification: {
              sourceId: "#{source_id_source}:#{source_id}"
            },
            access: access_props,
            administrative: {
              hasAdminPolicy: admin_policy_id,
              releaseTags: [
                {
                  to: 'Searchworks',
                  what: 'self',
                  date: '2015-07-27T18:43:32Z',
                  who: 'lauraw15',
                  release: true
                },
                {
                  to: 'Searchworks',
                  what: 'self',
                  date: '2015-10-25T21:12:42Z',
                  who: 'blalbrit',
                  release: true
                },
                {
                  to: 'Searchworks',
                  what: 'self',
                  date: '2016-07-15T23:44:01Z',
                  who: 'blalbrit',
                  release: false
                }
              ]
            },
            description: description_props
          }
        end
      end
    end

    context 'without release tags' do
      it_behaves_like 'Collection Identification Fedora Cocina mapping' do
        let(:collection_id) { 'druid:bh036kv6092' }
        let(:label) { 'Enlace' }
        let(:admin_policy_id) { 'druid:wp142hh6543' } # from RELS-EXT
        let(:source_id_source) { 'Hydrus' }
        let(:source_id) { 'collection-dhartwig-2013-03-19T16:43:27.792Z' }
        let(:other_id_name) { 'uuid' }
        let(:other_id) { '1fe81744-90b4-11e2-be35-0050569b3c6e' }
        let(:identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
              <adminPolicy>#{admin_policy_id}</adminPolicy>
              <otherId name="#{other_id_name}">#{other_id}</otherId>
              <tag>Project : Hydrus</tag>
              <objectType>set</objectType>
              <tag>Remediated By : 5.11.0</tag>
            </identityMetadata>
          XML
        end
        let(:roundtrip_identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
            </identityMetadata>
          XML
        end
        let(:cocina_props) do
          {
            externalIdentifier: collection_id,
            type: Cocina::Models::Vocab.collection,
            label: label,
            version: 1,
            identification: {
              sourceId: "#{source_id_source}:#{source_id}"
            },
            access: access_props,
            administrative: {
              hasAdminPolicy: admin_policy_id
            },
            description: description_props
          }
        end
      end
    end

    context 'with recent collection' do
      it_behaves_like 'Collection Identification Fedora Cocina mapping' do
        let(:collection_id) { 'druid:rs370pv0174' }
        let(:label) { 'Stanford University, University Architect / Campus Planning and Design, records' }
        let(:admin_policy_id) { 'druid:wp142hh6543' } # from RELS-EXT
        let(:source_id_source) { 'Hydrus' }
        let(:source_id) { 'collection-jschne-2018-02-08T16:42:44.515Z' }
        let(:other_id_name) { 'uuid' }
        let(:other_id) { '166c6046-0cef-11e8-9809-0050562259df' }
        let(:identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
              <otherId name="#{other_id_name}">#{other_id}</otherId>
              <tag>Project : Hydrus</tag>
              <objectType>set</objectType>
            </identityMetadata>
          XML
        end
        let(:roundtrip_identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
            </identityMetadata>
          XML
        end
        let(:cocina_props) do
          {
            externalIdentifier: collection_id,
            type: Cocina::Models::Vocab.collection,
            label: label,
            version: 1,
            identification: {
              sourceId: "#{source_id_source}:#{source_id}"
            },
            access: access_props,
            administrative: {
              hasAdminPolicy: admin_policy_id
            },
            description: description_props
          }
        end
      end
    end

    context 'with ckey and release tags' do
      it_behaves_like 'Collection Identification Fedora Cocina mapping' do
        let(:collection_id) { 'druid:bc225xg9715' }
        let(:label) { 'Generation Anthropocene' }
        let(:admin_policy_id) { 'druid:yp636tj5357' } # from RELS-EXT
        let(:source_id_source) { 'Hydrus' }
        let(:source_id) { 'collection-amyhodge-2013-03-15T18:27:56.741Z' }
        let(:other_id_name) { 'uuid' }
        let(:other_id) { '0ed6a40c-8d9e-11e2-998c-0050569b3c6e' }
        let(:identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
              <adminPolicy>#{admin_policy_id}</adminPolicy>
              <otherId name="#{other_id_name}">#{other_id}</otherId>
              <tag>Project : Hydrus</tag>
              <objectType>set</objectType>
              <release displayType="file" release="true" to="Searchworks" what="self" when="2016-10-03T21:55:25Z" who="blalbrit">true</release>
              <tag>Remediated By : 5.11.0</tag>
            </identityMetadata>
          XML
        end
        let(:roundtrip_identity_metadata_xml) do
          <<~XML
            <identityMetadata>
              <sourceId source="#{source_id_source}">#{source_id}</sourceId>
              <objectId>#{collection_id}</objectId>
              <objectCreator>DOR</objectCreator>
              <objectLabel>#{label}</objectLabel>
              <objectType>collection</objectType>
              <release to="Searchworks" what="self" when="2016-10-03T21:55:25Z" who="blalbrit">true</release>
            </identityMetadata>
          XML
        end
        let(:cocina_props) do
          {
            externalIdentifier: collection_id,
            type: Cocina::Models::Vocab.collection,
            label: label,
            version: 1,
            identification: {
              sourceId: "#{source_id_source}:#{source_id}"
            },
            access: access_props,
            administrative: {
              hasAdminPolicy: admin_policy_id,
              releaseTags: [
                {
                  to: 'Searchworks',
                  what: 'self',
                  date: '2016-10-03T21:55:25Z',
                  who: 'blalbrit',
                  release: true
                }
              ]
            },
            description: description_props
          }
        end
      end
    end
  end

  context 'with non-hydrus collection with catkey and uuid' do
    it_behaves_like 'Collection Identification Fedora Cocina mapping' do
      let(:collection_id) { 'druid:dj477pz3643' }
      let(:label) { 'Casa Zapata murals collection, 1984-1995' }
      let(:admin_policy_id) { 'druid:yf767bj4831' } # from RELS-EXT
      let(:catkey) { '7618375' }
      let(:other_id_name) { 'uuid' }
      let(:other_id) { 'f88d41aa-a8ef-11e9-a9e1-005056a7edb9' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{collection_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>collection</objectType>
            <otherId name="catkey">#{catkey}</otherId>
            <otherId name="#{other_id_name}">#{other_id}</otherId>
            <release what="collection" to="Searchworks" who="dhartwig" when="2019-07-19T19:40:30Z">true</release>
          </identityMetadata>
        XML
      end
      let(:roundtrip_identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <objectId>#{collection_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectLabel>#{label}</objectLabel>
            <objectType>collection</objectType>
            <otherId name="catkey">#{catkey}</otherId>
            <release what="collection" to="Searchworks" who="dhartwig" when="2019-07-19T19:40:30Z">true</release>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: collection_id,
          type: Cocina::Models::Vocab.collection,
          label: label,
          version: 1,
          identification: {
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          access: access_props,
          administrative: {
            hasAdminPolicy: admin_policy_id,
            releaseTags: [
              {
                to: 'Searchworks',
                what: 'collection',
                date: '2019-07-19T19:40:30Z',
                who: 'dhartwig',
                release: true
              }
            ]
          },
          description: description_props
        }
      end
    end
  end

  context 'with recent non-hydrus collection with catkey' do
    it_behaves_like 'Collection Identification Fedora Cocina mapping' do
      let(:collection_id) { 'druid:jm134xy3910' }
      let(:label) { 'Stanford Power2Act, Records' }
      let(:admin_policy_id) { 'druid:yf767bj4831' } # from RELS-EXT
      let(:catkey) { '13678509' }
      let(:identity_metadata_xml) do
        <<~XML
          <identityMetadata>
            <otherId name="catkey">#{catkey}</otherId>
            <objectLabel>#{label}</objectLabel>
            <objectId>#{collection_id}</objectId>
            <objectCreator>DOR</objectCreator>
            <objectType>collection</objectType>
          </identityMetadata>
        XML
      end
      let(:cocina_props) do
        {
          externalIdentifier: collection_id,
          type: Cocina::Models::Vocab.collection,
          label: label,
          version: 1,
          identification: {
            catalogLinks: [
              {
                catalog: 'symphony',
                catalogRecordId: catkey
              }
            ]
          },
          access: access_props,
          administrative: {
            hasAdminPolicy: admin_policy_id
          },
          description: description_props
        }
      end
    end
  end
end
