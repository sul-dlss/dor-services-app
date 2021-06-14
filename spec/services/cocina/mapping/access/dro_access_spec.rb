# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'DRO Access Fedora Cocina mapping' do
  # Required: rights_xml, cocina_access_props
  # Optional: roundtrip_rights_xml, embargo_xml, content_xml, roundtrip_content_xml, cocina_file_access_props

  let(:fedora_item) { Dor::Item.new }
  let(:mapped_access_props) { Cocina::FromFedora::DROAccess.props(fedora_item.rightsMetadata, fedora_item.embargoMetadata) }
  let(:mapped_structural_props) { Cocina::FromFedora::DroStructural.props(fedora_item, type: Cocina::Models::Vocab.book) }
  let(:cocina_file_access_props) { cocina_access_props }
  let(:roundtrip_rights_metadata_xml) { defined?(roundtrip_rights_xml) ? roundtrip_rights_xml : rights_xml }
  let(:normalized_orig_rights_xml) do
    # the starting rightsMetadata is normalized to address discrepancies found against rightsMetadata roundtripped
    #  to data store (Fedora) and back, per Andrew's specifications.
    #  E.g., license codes in use element become URL in license element
    orig_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
    Cocina::Normalizers::RightsNormalizer.normalize(datastream: orig_rights_metadata_ds).to_xml
  end
  let(:roundtrip_content_metadata_xml) { defined?(roundtrip_content_xml) ? roundtrip_content_xml : content_xml }
  let(:content_xml) do
    <<~XML
      <contentMetadata objectId="druid:db708qz9486" type="file">
        <resource id="http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f" sequence="1" type="file">
          <label/>
          <file id="sul-logo.png" mimetype="image/png" size="19823" publish="yes" shelve="yes" preserve="yes">
            <checksum type="sha1">b5f3221455c8994afb85214576bc2905d6b15418</checksum>
            <checksum type="md5">7142ce948827c16120cc9e19b05acd49</checksum>
            <imageData height="50" width="315"/>
          </file>
        </resource>
      </contentMetadata>
    XML
  end
  # we need cocina_structural_props to test file level access (via cocina_file_access_props passed in)
  let(:cocina_structural_props) do
    {
      contains: [
        {
          externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
          type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
          version: 1,
          structural: {
            contains: [
              {
                externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                label: 'sul-logo.png',
                filename: 'sul-logo.png',
                size: 19823,
                version: 1,
                hasMessageDigests: [
                  {
                    type: 'sha1',
                    digest: 'b5f3221455c8994afb85214576bc2905d6b15418'
                  },
                  {
                    type: 'md5',
                    digest: '7142ce948827c16120cc9e19b05acd49'
                  }
                ],
                access: cocina_file_access_props,
                administrative: {
                  publish: true,
                  sdrPreserve: true,
                  shelve: true
                },
                hasMimeType: 'image/png',
                presentation: {
                  height: 50,
                  width: 315
                }
              }
            ]
          },
          label: ''
        }
      ]
    }
  end

  before do
    rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
    allow(fedora_item).to receive(:rightsMetadata).and_return(rights_metadata_ds)
    if defined?(embargo_xml)
      embargo_metadata_ds = Dor::EmbargoMetadataDS.from_xml(embargo_xml)
      allow(fedora_item).to receive(:embargoMetadata).and_return(embargo_metadata_ds)
    end
    content_metadata_ds = Dor::ContentMetadataDS.from_xml(content_xml)
    allow(fedora_item).to receive(:contentMetadata).and_return(content_metadata_ds)
    allow(Cocina::IdGenerator).to receive(:generate_or_existing_fileset_id).and_return('http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f')
    allow(Cocina::IdGenerator).to receive(:generate_file_id).and_return('http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181')
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina DROAccess' do
      expect { Cocina::Models::DROAccess.new(cocina_access_props) }.not_to raise_error
    end

    it 'cocina hash produces valid Cocina DROStructural' do
      expect { Cocina::Models::DROStructural.new(cocina_structural_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_access_props).to be_deep_equal(cocina_access_props)
      expect(mapped_structural_props).to be_deep_equal(cocina_structural_props)
    end
  end

  context 'when mapping from Cocina to Fedora' do
    let(:mapped_access) { Cocina::Models::DROAccess.new(mapped_access_props) }
    let(:mapped_structural) { Cocina::Models::DROStructural.new(mapped_structural_props) }
    let(:mapped_roundtrip_content_xml) { fedora_item.contentMetadata.to_xml }

    before do
      Cocina::ToFedora::DROAccess.apply(fedora_item, mapped_access, mapped_structural)
    end

    it 'rightsMetadata roundtrips thru cocina model to provided expected rightsMetadata.xml' do
      # for some reason, fedora_item.rightsMetadata.ng_xml.to_xml fails here, but fedora_item.rightsMetadata.to_xml passes.
      #   ? Maybe some encoding assumptions baked in to active fedora.  Likewise, the opposite is true for the test below.
      expect(fedora_item.rightsMetadata.to_xml).to be_equivalent_to(roundtrip_rights_metadata_xml)
    end

    it 'rightsMetadata roundtrips thru cocina model to normalized original rightsMetadata.xml' do
      # for some reason, fedora_item.rightsMetadata.to_xml fails here, but fedora_item.rightsMetadata.ng_xml.to_xml passes.
      #    ? Maybe some encoding assumptions baked in to active fedora.  Likewise, the opposite is true for the test above.
      expect(fedora_item.rightsMetadata.ng_xml.to_xml).to be_equivalent_to(normalized_orig_rights_xml)
    end

    it 'contentMetadata roundtrips thru cocina model to original contentMetadata.xml' do
      expect(mapped_roundtrip_content_xml).to be_equivalent_to(roundtrip_content_metadata_xml)
    end
  end

  context 'when mapping from roundtrip Fedora to (roundtrip) Cocina' do
    let(:roundtrip_fedora_item) { Dor::Item.new }
    let(:roundtrip_access_props) { Cocina::FromFedora::DROAccess.props(roundtrip_fedora_item.rightsMetadata, roundtrip_fedora_item.embargoMetadata) }
    let(:roundtrip_structural_props) { Cocina::FromFedora::DroStructural.props(roundtrip_fedora_item, type: Cocina::Models::Vocab.book) }

    before do
      roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(roundtrip_rights_metadata_xml)
      allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
      if defined?(embargo_xml)
        embargo_metadata_ds = Dor::EmbargoMetadataDS.from_xml(embargo_xml)
        allow(roundtrip_fedora_item).to receive(:embargoMetadata).and_return(embargo_metadata_ds)
      end
      roundtrip_content_metadata_ds = Dor::ContentMetadataDS.from_xml(roundtrip_content_metadata_xml)
      allow(roundtrip_fedora_item).to receive(:contentMetadata).and_return(roundtrip_content_metadata_ds)
    end

    it 'roundtrip Fedora maps to expected Cocina object props' do
      expect(roundtrip_access_props).to be_deep_equal(cocina_access_props)
      expect(roundtrip_structural_props).to be_deep_equal(cocina_structural_props)
    end
  end

  context 'when mapping from normalized orig Fedora rights_xml to (roundtrip) Cocina' do
    let(:roundtrip_fedora_item) { Dor::Item.new }
    let(:roundtrip_access_props) { Cocina::FromFedora::DROAccess.props(roundtrip_fedora_item.rightsMetadata, roundtrip_fedora_item.embargoMetadata) }
    let(:roundtrip_structural_props) { Cocina::FromFedora::DroStructural.props(roundtrip_fedora_item, type: Cocina::Models::Vocab.book) }

    before do
      roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(normalized_orig_rights_xml)
      allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
      if defined?(embargo_xml)
        embargo_metadata_ds = Dor::EmbargoMetadataDS.from_xml(embargo_xml)
        allow(roundtrip_fedora_item).to receive(:embargoMetadata).and_return(embargo_metadata_ds)
      end
      roundtrip_content_metadata_ds = Dor::ContentMetadataDS.from_xml(roundtrip_content_metadata_xml)
      allow(roundtrip_fedora_item).to receive(:contentMetadata).and_return(roundtrip_content_metadata_ds)
    end

    it 'normalized Fedora rights_xml maps to expected Cocina object props' do
      expect(roundtrip_access_props).to be_deep_equal(cocina_access_props)
      expect(roundtrip_structural_props).to be_deep_equal(cocina_structural_props)
    end
  end
end

RSpec.describe 'Fedora item rights/statements/licenses <--> Cocina DRO access mappings' do
  context 'with world access - minimal' do
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with world object access - dark file access' do
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
            <access type="read">
              <file>sul-logo.png</file>
              <machine>
                <none/>
              </machine>
            </access>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'dark',
          download: 'none'
        }
      end
    end
  end

  context 'with world access, copyright, useAndReproduction, license' do
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
              <human type="useAndReproduction">blah blah</human>
              <human type="creativeCommons">Attribution Non-Commercial, No Derivatives 3.0 Unported</human>
              <machine type="creativeCommons">by-nc-nd</machine>
            </use>
            <copyright>
              <human>&#xA9;2021 Wingnut and Vinsky publishing</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:roundtrip_rights_xml) do
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
              <human type="useAndReproduction">blah blah</human>
              <license>https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode</license>
            </use>
            <copyright>
              <human>&#xA9;2021 Wingnut and Vinsky publishing</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          copyright: '©2021 Wingnut and Vinsky publishing',
          download: 'world',
          useAndReproductionStatement: 'blah blah',
          license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with full example from https://github.com/sul-dlss/cocina-models/issues/236' do
    # from bb001xb8305
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
              <human type="creativeCommons">Public Domain Mark 1.0</human>
              <machine type="creativeCommons" uri="https://creativecommons.org/publicdomain/mark/1.0/">pdm</machine>
              <human type="useAndReproduction">hrrm hoo hum</human>
            </use>
            <copyright>
              <human>Public Domain.</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:roundtrip_rights_xml) do
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
              <license>https://creativecommons.org/publicdomain/mark/1.0/</license>
              <human type="useAndReproduction">hrrm hoo hum</human>
            </use>
            <copyright>
              <human>Public Domain.</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          copyright: 'Public Domain.',
          download: 'world',
          license: 'https://creativecommons.org/publicdomain/mark/1.0/',
          useAndReproductionStatement: 'hrrm hoo hum'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with new style license specification (world access)' do
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
              <license>https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode</license>
            </use>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with rightsMetadata that has accessCondition' do
    # based on bk689jd2364
    # see https://github.com/sul-dlss/argo/issues/2552
    # it_behaves_like 'DRO Access Fedora Cocina mapping' do
    xit 'FIXME: accessCondition element in rightsMetadata should error (?)' do
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
            <accessCondition type="license">CC pdm: Public Domain Mark 1.0</accessCondition>
            <use>
              <human type="useAndReproduction">baroque</human>
            </use>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          useAndReproductionStatement: 'baroque',
          license: 'https://creativecommons.org/licenses/pdm/????'
        }
      end
    end
  end

  context 'with useAndReproduction and no copyright' do
    # From bb000kg4251
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
              <human type="useAndReproduction">wacka wacka wacka</human>
            </use>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          useAndReproductionStatement: 'wacka wacka wacka'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with copyright' do
    # from https://argo.stanford.edu/view/druid:bb003dn0409
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
              <human type="useAndReproduction">Official WTO documents are free for public use.</human>
              <human type="creativeCommons"/>
              <machine type="creativeCommons"/>
            </use>
            <copyright>
              <human>Copyright &#xA9; World Trade Organization</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          copyright: 'Copyright © World Trade Organization',
          useAndReproductionStatement: 'Official WTO documents are free for public use.'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with copyright but no use statement (contrived example)' do
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
              <human>Copyright &#xA9; DLSS</human>
            </copyright>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          copyright: 'Copyright © DLSS'
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  context 'with an embargo' do
    # from https://argo.stanford.edu/view/druid:bb003dn0409
    it_behaves_like 'DRO Access Fedora Cocina mapping' do
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

      let(:embargo_xml) do
        <<~XML
          <embargoMetadata>
            <status>embargoed</status>
            <releaseDate>2029-02-28T00:00:00Z</releaseDate>
            <releaseAccess>
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
                <human type="useAndReproduction">in public domain</human>
              </use>
            </releaseAccess>
          </embargoMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          embargo:
            {
              access: 'world',
              download: 'world',
              releaseDate: DateTime.parse('2029-02-28'),
              useAndReproductionStatement: 'in public domain'
            }
        }
      end

      let(:cocina_file_access_props) do
        {
          access: 'world',
          download: 'world'
        }
      end
    end
  end

  describe 'license types' do
    context 'with an ODC license (default access = dark)' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <human type="openDataCommons">Open Data Commons Attribution License 1.0</human>
                <machine type="openDataCommons">odc-by</machine>
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

        let(:roundtrip_rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>https://opendatacommons.org/licenses/by/1-0/</license>
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
            download: 'none',
            license: 'https://opendatacommons.org/licenses/by/1-0/'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'dark',
            download: 'none'
          }
        end
      end
    end

    context 'with a CC license (default access = dark)' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <human type="creativeCommons">Attribution Non-Commercial, No Derivatives 3.0 Unported</human>
                <machine type="creativeCommons">by-nc-nd</machine>
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

        let(:roundtrip_rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode</license>
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
            download: 'none',
            license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'dark',
            download: 'none'
          }
        end
      end
    end

    context 'with CC 4.0 license' do
      # based on bd324jt9731
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                <human type="creativeCommons">CC-BY SA 4.0</human>
                <machine type="creativeCommons" uri="https://creativecommons.org/licenses/by-sa/4.0/legalcode">by-sa</machine>
                <human type="useAndReproduction">we are all one</human>
              </use>
            </rightsMetadata>
          XML
        end

        let(:roundtrip_rights_xml) do
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
                <license>https://creativecommons.org/licenses/by-sa/4.0/legalcode</license>
                <human type="useAndReproduction">we are all one</human>
              </use>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'world',
            download: 'world',
            useAndReproductionStatement: 'we are all one',
            license: 'https://creativecommons.org/licenses/by-sa/4.0/legalcode'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'world',
            download: 'world'
          }
        end
      end
    end

    context 'with a "none" license (default access = dark)' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <human type="creativeCommons">no Creative Commons (CC) license</human>
                <machine type="creativeCommons">none</machine>
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
            download: 'none',
            license: 'http://cocina.sul.stanford.edu/licenses/none'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'dark',
            download: 'none'
          }
        end
      end
    end

    context 'with cc0 (default access = dark)' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>https://creativecommons.org/publicdomain/zero/1.0/legalcode</license>
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

        let(:roundtrip_rights_xml) do
          <<~XML
            <rightsMetadata>
              <use>
                <license>https://creativecommons.org/publicdomain/zero/1.0/legalcode</license>
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
            download: 'none',
            license: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'dark',
            download: 'none'
          }
        end
      end
    end
  end

  describe 'access and download rights' do
    context 'when citation-only' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <none/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'citation-only',
            download: 'none'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'dark',
            download: 'none'
          }
        end
      end
    end

    context 'when citation-only -- world file access' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <none/>
                </machine>
              </access>
              <access type="read">
                <file>sul-logo.png</file>
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'citation-only',
            download: 'none'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'world',
            download: 'world'
          }
        end
      end
    end

    context 'when controlled digital lending' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <cdl>
                    <group rule="no-download">stanford</group>
                  </cdl>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'stanford',
            controlledDigitalLending: true,
            download: 'none'
          }
        end
      end
    end

    context 'when dark' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
            access: 'dark',
            download: 'none'
          }
        end
      end
    end

    context 'when stanford' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <group>stanford</group>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'stanford',
            download: 'stanford'
          }
        end
      end
    end

    context 'when stanford (no-download) -- world file access' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <group rule="no-download">stanford</group>
                </machine>
              </access>
              <access type="read">
                <file>sul-logo.png</file>
                <machine>
                  <world/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'stanford',
            download: 'none',
            controlledDigitalLending: false
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'world',
            download: 'world'
          }
        end
      end
    end

    context 'when stanford + world (no-download)' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <group>stanford</group>
                </machine>
              </access>
              <access type="read">
                <machine>
                  <world rule="no-download"/>
                </machine>
              </access>
            </rightsMetadata>
          XML
        end

        let(:cocina_access_props) do
          {
            access: 'world',
            download: 'stanford'
          }
        end
      end
    end

    context 'when world' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
            access: 'world',
            download: 'world'
          }
        end
      end
    end

    context 'when world (no-download) -- world file access' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                  <world rule="no-download"/>
                </machine>
              </access>
              <access type="read">
                <file>sul-logo.png</file>
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
            download: 'none'
          }
        end

        let(:cocina_file_access_props) do
          {
            access: 'world',
            download: 'world'
          }
        end
      end
    end

    ['ars', 'art', 'hoover', 'm&m', 'music', 'spec'].each do |location|
      context "with location:#{location}" do
        it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                    <location>#{CGI.escapeHTML(location)}</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end

          let(:cocina_access_props) do
            {
              access: 'location-based',
              readLocation: location,
              download: 'location-based'
            }
          end
        end
      end

      context "with location:#{location} (no-download)" do
        it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                    <location rule="no-download">#{CGI.escapeHTML(location)}</location>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end

          let(:cocina_access_props) do
            {
              access: 'location-based',
              readLocation: location,
              download: 'none'
            }
          end
        end
      end

      context "with location:#{location} + stanford (no-download)" do
        it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                    <location>#{CGI.escapeHTML(location)}</location>
                  </machine>
                </access>
                <access type="read">
                  <machine>
                    <group rule="no-download">stanford</group>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end

          let(:cocina_access_props) do
            {
              access: 'stanford',
              readLocation: location,
              download: 'location-based'
            }
          end
        end
      end

      context "with location:#{location} + world (no-download)" do
        it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
                    <location>#{CGI.escapeHTML(location)}</location>
                  </machine>
                </access>
                <access type="read">
                  <machine>
                    <world rule="no-download"/>
                  </machine>
                </access>
              </rightsMetadata>
            XML
          end

          let(:cocina_access_props) do
            {
              access: 'world',
              download: 'location-based',
              readLocation: location
            }
          end
        end
      end
    end
  end
end
