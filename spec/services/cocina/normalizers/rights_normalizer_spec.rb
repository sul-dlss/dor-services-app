# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::RightsNormalizer do
  let(:normalized_original_ng_xml) { described_class.normalize(datastream: object_rights_ds) }
  let(:object_rights_ds) { Dor::RightsMetadataDS.new }

  before { allow(object_rights_ds).to receive(:ng_xml).and_return(original_ng_xml) }

  describe '#normalize_license_to_uri' do
    context 'when use element contains more than human and machine license info' do
      let(:original_ng_xml) do
        Nokogiri::XML <<~XML
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

      it 'removes createCommons licenses from original rights xml and adds correct license URI' do
        expect(original_ng_xml.root.xpath("//use/machine[@type='creativeCommons' and text()]").size).to eq(1)
        expect(original_ng_xml.root.xpath("//use/human[@type='creativeCommons' and text()]").size).to eq(1)
        expect(original_ng_xml.root.xpath('//use/license').size).to eq(0)
        expect(normalized_original_ng_xml.root.xpath("//use/machine[@type='creativeCommons' and text()]").size).to eq(0)
        expect(normalized_original_ng_xml.root.xpath("//use/human[@type='creativeCommons' and text()]").size).to eq(0)
        expect(normalized_original_ng_xml.root.xpath('//use/license').size).to eq(1)
        expect(normalized_original_ng_xml.root.xpath('//use/license').first.text).to eq('https://creativecommons.org/licenses/by-nc/3.0/')
      end

      it 'leaves use and reproduction statement in all cases' do
        expect(original_ng_xml.root.xpath("//use/human[@type='useAndReproduction']").first.text).to eq('Use at will.')
        expect(normalized_original_ng_xml.root.xpath("//use/human[@type='useAndReproduction']").first.text).to eq('Use at will.')
      end
    end

    context 'when use element contains human and machine license info only' do
      let(:original_ng_xml) do
        Nokogiri::XML <<~XML
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
              <human type="creativeCommons">CC BY-NC Attribution-NonCommercial</human>
              <machine type="creativeCommons">by-nc</machine>
            </use>
          </rightsMetadata>
        XML
      end

      it 'removes createCommons licenses from original rights xml and adds license URI' do
        expect(normalized_original_ng_xml.root.xpath("//use/machine[@type='creativeCommons' and text()]").size).to eq(0)
        expect(normalized_original_ng_xml.root.xpath("//use/human[@type='creativeCommons' and text()]").size).to eq(0)
        expect(normalized_original_ng_xml.root.xpath('//use/license').size).to eq(1)
        expect(normalized_original_ng_xml.root.xpath('//use/license').first.text).to eq('https://creativecommons.org/licenses/by-nc/3.0/')
      end
    end

    context 'when use element contains only license' do
      let(:original_ng_xml) do
        Nokogiri::XML <<~XML
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
              <license>https://creativecommons.org/licenses/by-nc/3.0/</license>
            </use>
          </rightsMetadata>
        XML
      end

      it 'keeps the license URI' do
        expect(normalized_original_ng_xml.root.xpath('//use/license').size).to eq(1)
        expect(normalized_original_ng_xml.root.xpath('//use/license').first.text).to eq('https://creativecommons.org/licenses/by-nc/3.0/')
      end
    end

    context 'when use element contains license and useAndReproduction' do
      let(:original_ng_xml) do
        Nokogiri::XML <<~XML
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
              <license>https://creativecommons.org/licenses/by-nc/3.0/</license>
            </use>
          </rightsMetadata>
        XML
      end

      it 'keeps the license URI' do
        expect(normalized_original_ng_xml.root.xpath('//use/human').size).to eq(1)
        expect(normalized_original_ng_xml.root.xpath('//use/license').size).to eq(1)
        expect(normalized_original_ng_xml.root.xpath('//use/license').first.text).to eq('https://creativecommons.org/licenses/by-nc/3.0/')
      end
    end
  end
end
