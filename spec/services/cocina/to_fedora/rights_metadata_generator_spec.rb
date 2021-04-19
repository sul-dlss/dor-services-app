# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::RightsMetadataGenerator do
  subject(:generate) do
    described_class.generate(rights: rights, access: access)
  end

  let(:access) { Cocina::Models::DROAccess.new(JSON.parse(cocina)) }
  let(:item) { instantiate_fixture('druid:hj097bm8879', Dor::Item) }
  let(:rights) { item.rightsMetadata }
  let(:rights_statements) do
    <<~XML
      <use>
        <human type="creativeCommons">Attribution Non-Commercial Share Alike 3.0 Unported</human>
        <machine type="creativeCommons">by-nc-sa</machine>
      </use>
      <use>
        <human type="useAndReproduction">To obtain permission to publish or reproduce commercially, please contact the Digital  Rare Map Librarian, David Rumsey Map Center at rumseymapcenter@stanford.edu.</human>
      </use>
      <copyright>
        <human type="copyright">Property rights reside with the repository, Copyright &#xA9; Stanford University. Images may be reproduced or transmitted, but not for commercial use. For commercial use or commercial republication, contact rumseymapcenter@stanford.edu This work is licensed under a Creative Commons License. By downloading any images from this site, you agree to the terms of that license.</human>
      </copyright>
    XML
  end

  context 'when citation-only' do
    let(:cocina) do
      <<~JSON
        {
          "access": "citation-only",
          "download": "none"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when controlled digital lending' do
    let(:cocina) do
      <<~JSON
        {
          "access": "stanford",
          "controlledDigitalLending": true,
          "download": "none"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when dark' do
    let(:cocina) do
      <<~JSON
        {
          "access": "dark",
          "download": "none"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when stanford' do
    let(:cocina) do
      <<~JSON
        {
          "access": "stanford",
          "download": "stanford"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when stanford (no-download)' do
    let(:cocina) do
      <<~JSON
        {
          "access": "stanford",
          "download": "none"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when stanford + world (no-download)' do
    let(:cocina) do
      <<~JSON
        {
          "access": "world",
          "download": "stanford"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when world' do
    let(:cocina) do
      <<~JSON
        {
          "access": "world",
          "download": "world"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  context 'when world (no-download)' do
    let(:cocina) do
      <<~JSON
        {
          "access": "world",
          "download": "none"
        }
      JSON
    end

    it 'maps rights metadata as expected' do
      expect(generate).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
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
          #{rights_statements}
        </rightsMetadata>
      XML
    end
  end

  ['ars', 'art', 'hoover', 'm&m', 'music', 'spec'].each do |location|
    context "when location:#{location}" do
      let(:cocina) do
        <<~JSON
          {
            "access": "location-based",
            "download": "location-based",
            "readLocation": "#{location}"
          }
        JSON
      end

      it 'maps rights metadata as expected' do
        expect(generate).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
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
            #{rights_statements}
          </rightsMetadata>
        XML
      end
    end

    context "when location:#{location} (no-download)" do
      let(:cocina) do
        <<~JSON
          {
            "access": "location-based",
            "download": "none",
            "readLocation": "#{location}"
          }
        JSON
      end

      it 'maps rights metadata as expected' do
        expect(generate).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
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
            #{rights_statements}
          </rightsMetadata>
        XML
      end
    end

    context "when location:#{location} + stanford (no-download)" do
      let(:cocina) do
        <<~JSON
          {
            "access": "stanford",
            "download": "location-based",
            "readLocation": "#{location}"
          }
        JSON
      end

      it 'maps rights metadata as expected' do
        expect(generate).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
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
            #{rights_statements}
          </rightsMetadata>
        XML
      end
    end

    context "when location:#{location} + world (no-download)" do
      let(:cocina) do
        <<~JSON
          {
            "access": "world",
            "download": "location-based",
            "readLocation": "#{location}"
          }
        JSON
      end

      it 'maps rights metadata as expected' do
        expect(generate).to be_equivalent_to <<~XML
          <?xml version="1.0"?>
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
            #{rights_statements}
          </rightsMetadata>
        XML
      end
    end
  end
end
