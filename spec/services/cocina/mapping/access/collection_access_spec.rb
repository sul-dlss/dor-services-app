# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'Collection Access Fedora Cocina mapping' do
  # Required: rights_xml, cocina_access_props
  # Optional: roundtrip_rights_xml

  let(:fedora_collection) { Dor::Collection.new }
  let(:mapped_coll_access_props) { Cocina::FromFedora::Access.collection_props(fedora_collection.rightsMetadata) }
  let(:roundtrip_rights_metadata_xml) { defined?(roundtrip_rights_xml) ? roundtrip_rights_xml : rights_xml }

  before do
    rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
    allow(fedora_collection).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina (Collection) Access' do
      expect { Cocina::Models::Access.new(cocina_access_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_coll_access_props).to be_deep_equal(cocina_access_props)
    end
  end

  context 'when mapping from Cocina to Fedora' do
    let(:mapped_coll_access) { Cocina::Models::Access.new(mapped_coll_access_props) }
    let(:mapped_roundtrip_rights_xml) do
      Cocina::ToFedora::Access.apply(fedora_collection, mapped_coll_access)
      fedora_collection.rightsMetadata.to_xml
    end

    it 'rightsMetadata roundtrips thru cocina model to original rightsMetadata.xml' do
      expect(mapped_roundtrip_rights_xml).to be_equivalent_to(roundtrip_rights_metadata_xml)
    end
  end

  context 'when mapping from roundtrip Fedora to Cocina' do
    let(:roundtrip_fedora_collection) { Dor::Collection.new }
    let(:roundtrip_cocina_props) { Cocina::FromFedora::Access.collection_props(roundtrip_fedora_collection.rightsMetadata) }

    before do
      roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(roundtrip_rights_metadata_xml)
      allow(roundtrip_fedora_collection).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
    end

    it 'roundtrip Fedora maps to expected Cocina (collection) Access props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_access_props)
    end
  end
end

RSpec.describe 'Fedora collection rights <--> Cocina Collection access mappings' do
  context 'with world access (minimal)' do
    it_behaves_like 'Collection Access Fedora Cocina mapping' do
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

      let(:cocina_access_props) do
        {
          access: 'world'
        }
      end
    end
  end

  context 'with dark access (minimal)' do
    it_behaves_like 'Collection Access Fedora Cocina mapping' do
      let(:rights_xml) do
        <<~XML
          <rightsMetadata>
            <access type="discover">
              <machine>
                <none/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'dark'
        }
      end
    end
  end

  describe 'licenses' do
    context 'with an ODC license (default access)' do
      it_behaves_like 'Collection Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
                <machine type="openDataCommons">odc-by</machine>
              </use>
            </rightsMetadata>
          XML
        end

        let(:roundtrip_rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>http://opendatacommons.org/licenses/by/1.0/</license>
              </use>
              <access type="discover">
                <machine>
                  <none/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'dark',
            license: 'http://opendatacommons.org/licenses/by/1.0/'
          }
        end
      end
    end

    context 'with a CC license (world access)' do
      it_behaves_like 'Collection Access Fedora Cocina mapping' do
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
              <use>
                <human type="creativeCommons">Attribution Non-Commercial, No Derivatives 3.0 Unported</human>
                <machine type="creativeCommons">by-nc-nd</machine>
              </use>
            </rightsMetadata>
          XML
        end

        let(:roundtrip_rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>https://creativecommons.org/licenses/by-nc-nd/3.0/</license>
              </use>
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

        let(:cocina_access_props) do
          {
            access: 'world',
            license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/'
          }
        end
      end
    end

    context 'with a "none" license (dark access)' do
      it_behaves_like 'Collection Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
              <access type="discover">
                <machine>
                  <none/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
              <use>
                <human type="creativeCommons">no Creative Commons (CC) license</human>
                <machine type="creativeCommons">none</machine>
              </use>
            </rightsMetadata>
          XML
        end

        let(:roundtrip_rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>http://cocina.sul.stanford.edu/licenses/none</license>
              </use>
              <access type="discover">
                <machine>
                  <none/>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'dark',
            license: 'http://cocina.sul.stanford.edu/licenses/none'
          }
        end
      end
    end
  end

  context 'with a use statement (default access)' do
    it_behaves_like 'Collection Access Fedora Cocina mapping' do
      let(:rights_xml) do
        <<~XML
          <rightsMetadata>
            <use>
              <human type="useAndReproduction">User agrees that, where applicable, stuff.</human>
            </use>
          </rightsMetadata>
        XML
      end

      let(:roundtrip_rights_xml) do
        <<~XML
          <rightsMetadata>
            <use>
              <human type="useAndReproduction">User agrees that, where applicable, stuff.</human>
            </use>
            <access type="discover">
              <machine>
                <none/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'dark',
          useAndReproductionStatement: 'User agrees that, where applicable, stuff.'
        }
      end
    end
  end

  context 'with a copyright statement (world access)' do
    it_behaves_like 'Collection Access Fedora Cocina mapping' do
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
            <copyright>
              <human>&#xA9;2021 Wingnut and Vinsky publishing</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          copyright: '©2021 Wingnut and Vinsky publishing'
        }
      end
    end
  end
end
