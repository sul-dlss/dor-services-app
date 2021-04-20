# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_examples 'DRO Access Fedora Cocina mapping' do
  # Required: rights_xml, cocina_access_props
  # Optional: embargo_props, roundtrip_rights_xml

  let(:cocina_embargo_props) { defined?(embargo_props) ? embargo_props : nil }
  let(:fedora_item_obj) { Dor::Item.new }
  let(:mapped_dro_access_props) { Cocina::FromFedora::DROAccess.props(fedora_item_obj.rightsMetadata, embargo: cocina_embargo_props) }
  let(:roundtrip_rights_metadata_xml) { defined?(roundtrip_rights_xml) ? roundtrip_rights_xml : rights_xml }

  before do
    rights_metadata_ds = Dor::RightsMetadataDS.from_xml(rights_xml)
    allow(fedora_item_obj).to receive(:rightsMetadata).and_return(rights_metadata_ds)
  end

  context 'when mapping from Fedora to Cocina' do
    it 'cocina hash produces valid Cocina DROAccess' do
      expect { Cocina::Models::DROAccess.new(cocina_access_props) }.not_to raise_error
    end

    it 'Fedora maps to expected Cocina' do
      expect(mapped_dro_access_props).to be_deep_equal(cocina_access_props)
    end
  end

  context 'when mapping from Cocina to Fedora' do
    let(:mapped_dro_access) { Cocina::Models::DROAccess.new(mapped_dro_access_props) }
    let(:mapped_roundtrip_rights_xml) do
      Cocina::ToFedora::DROAccess.apply(fedora_item_obj, mapped_dro_access)
      fedora_item_obj.rightsMetadata.to_xml
    end

    it 'rightsMetadata roundtrips thru cocina model to original rightsMetadata.xml' do
      expect(mapped_roundtrip_rights_xml).to be_equivalent_to(roundtrip_rights_metadata_xml)
    end
  end

  context 'when mapping from roundtrip Fedora to Cocina' do
    let(:roundtrip_fedora_item) { Dor::Item.new }
    let(:roundtrip_cocina_props) { Cocina::FromFedora::DROAccess.props(roundtrip_fedora_item.rightsMetadata, embargo: cocina_embargo_props) }

    before do
      roundtrip_rights_metadata_ds = Dor::RightsMetadataDS.from_xml(roundtrip_rights_metadata_xml)
      allow(roundtrip_fedora_item).to receive(:rightsMetadata).and_return(roundtrip_rights_metadata_ds)
    end

    it 'roundtrip Fedora maps to expected Cocina object props' do
      expect(roundtrip_cocina_props).to be_deep_equal(cocina_access_props)
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
              <license>https://creativecommons.org/licenses/by-nc-nd/3.0/</license>
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
          license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/'
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
              <license>https://creativecommons.org/licenses/by-nc-nd/3.0/</license>
            </use>
          </rightsMetadata>
        XML
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/'
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
              <machine type="creativeCommons" uri="https://creativecommons.org/licenses/by-sa/4.0/">by-sa</machine>
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
              <license>https://creativecommons.org/licenses/by-sa/4.0/</license>
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
          license: 'https://creativecommons.org/licenses/by-sa/4.0/'
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

      let(:embargo_props) do
        {
          releaseDate: DateTime.parse('2029-02-28'),
          access: 'world',
          useAndReproductionStatement: 'in public domain'
        }
      end

      let(:cocina_access_props) do
        {
          access: 'world',
          download: 'world',
          embargo:
            {
              access: 'world',
              releaseDate: DateTime.parse('2029-02-28'),
              useAndReproductionStatement: 'in public domain'
            }
        }
      end
    end
  end

  describe 'license types' do
    context 'with an ODC license' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
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
            download: 'none',
            license: 'http://opendatacommons.org/licenses/by/1.0/'
          }
        end
      end
    end

    context 'with a CC license' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
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
            license: 'https://creativecommons.org/licenses/by-nc-nd/3.0/'
          }
        end
      end
    end

    context 'with a "none" license' do
      it_behaves_like 'DRO Access Fedora Cocina mapping' do
        let(:rights_xml) do
          <<~XML
            <rightsMetadata>
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
            download: 'none',
            license: 'http://cocina.sul.stanford.edu/licenses/none'
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

    context 'when stanford (no-download) with file level read' do
      # it_behaves_like 'DRO Access Fedora Cocina mapping' do
      xit 'waiting for file level access implementation' do
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
                <file>foo_bar.pdf</file>
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
            download: 'none'
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

    context 'when world (no-download) with file level read' do
      # it_behaves_like 'DRO Access Fedora Cocina mapping' do
      xit 'waiting for file level access implementation' do
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
                <file>foo_bar.pdf</file>
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
