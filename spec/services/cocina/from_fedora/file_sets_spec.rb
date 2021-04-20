# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::FileSets do
  let(:content_xml) do
    <<~XML
      <contentMetadata objectId="druid:gs491bt1345" type="media">
        <resource id="gs491bt1345_1" sequence="1" type="audio">
          <label>Audio file</label>
          <file id="gs491bt1345_sample_01_00_pm.wav" mimetype="audio/x-wav" size="299569842" publish="no" shelve="no" preserve="yes">
            <checksum type="sha1">ccde1331b5bc6c3dce0231c352c7a11f1fd3e77f</checksum>
            <checksum type="md5">d46055f03b4a9dc30fcfdfebea473127</checksum>
          </file>
          <file id="gs491bt1345_sample_01_00_sh.wav" mimetype="audio/x-wav" size="91743738" publish="no" shelve="no" preserve="yes">
            <checksum type="sha1">a9cb4668c42c5416a301759ff40fe365ea2467a3</checksum>
            <checksum type="md5">188c0c972bc039c679bf984e75c7500e</checksum>
          </file>
          <file id="gs491bt1345_sample_01_00_sl.m4a" mimetype="audio/mp4" size="16798755" publish="yes" shelve="yes" preserve="yes">
            <checksum type="sha1">8d95b3b77f900b6d229ee32d05f927d75cbce032</checksum>
            <checksum type="md5">b044b593d0d444180e82de064594339a</checksum>
          </file>
        </resource>
        <resource id="gs491bt1345_2" sequence="2" type="file">
          <label>Program PDF</label>
          <file id="gs491bt1345_sample_md.pdf" mimetype="application/pdf" size="930089" publish="yes" shelve="yes" preserve="yes">
            <checksum type="sha1">3b342f7b87f126997088720c1220122d41c8c159</checksum>
            <checksum type="md5">6ed0004f39657ff81dff7b2b017fb9d9</checksum>
          </file>
        </resource>
      </contentMetadata>
    XML
  end
  let(:ignore_resource_type_errors) { false }
  let(:instance) do
    described_class.new(content_metadata_ds,
                        rights_metadata: rights_metadata_ds,
                        version: 1,
                        ignore_resource_type_errors: ignore_resource_type_errors)
  end
  let(:content_metadata_ds) do
    instance_double(Dor::ContentMetadataDS,
                    ng_xml: Nokogiri::XML(content_xml))
  end
  let(:rights_metadata_ds) do
    instance_double(Dor::RightsMetadataDS,
                    new?: false,
                    ng_xml: Nokogiri::XML(rights_xml),
                    dra_object: Dor::RightsAuth.parse(rights_xml, true))
  end
  let(:rights_xml) do
    <<~XML
      <rightsMetadata>
      </rightsMetadata>
    XML
  end

  describe '#resource_type' do
    subject { instance.send(:resource_type, node) }

    let(:node) { Nokogiri::XML::DocumentFragment.parse("<resource type=\"#{type}\" />").at_css('resource') }

    context 'when type is main-augmented (ETDs)' do
      let(:type) { 'main-augmented' }

      it { is_expected.to eq 'http://cocina.sul.stanford.edu/models/resources/main-augmented.jsonld' }
    end

    context 'when type is 3d' do
      let(:type) { '3d' }

      it { is_expected.to eq 'http://cocina.sul.stanford.edu/models/resources/3d.jsonld' }
    end

    context 'when the resource type is invalid' do
      let(:type) { 'bogus' }

      before { allow(Honeybadger).to receive(:notify) }

      context 'when ignore_resource_type_errors is not set' do
        it 'notifies Honeybadger' do
          instance.send(:resource_type, node)
          expect(Honeybadger).to have_received(:notify)
        end
      end

      context 'when ignore_resource_type_errors is set' do
        let(:ignore_resource_type_errors) { true }

        it 'does not notify Honeybadger' do
          instance.send(:resource_type, node)
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end
  end

  describe 'file-level access rights' do
    let(:rights_xml) do
      <<~XML
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
          #{file_specific_rights}
        </rightsMetadata>
      XML
    end
    let(:rights_metadata_ds) do
      instance_double(Dor::RightsMetadataDS,
                      new?: false,
                      ng_xml: Nokogiri::XML(rights_xml),
                      dra_object: Dor::RightsAuth.parse(rights_xml, true))
    end
    let(:item_cocina_rights) do
      {
        access: 'world',
        download: 'world'
      }
    end
    let(:type) { Cocina::Models::Vocab.media }
    let(:structural) { instance.build }
    let(:audio_fileset) { structural.first[:structural][:contains] }
    let(:text_fileset) { structural.last[:structural][:contains] }

    context 'when controlled digital lending' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <cdl>
                <group rule="no-download">stanford</group>
              </cdl>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'stanford', controlledDigitalLending: true, download: 'none')
      end
    end

    context 'when dark' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <none/>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'dark', download: 'none')
      end
    end

    context 'when stanford' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <group>stanford</group>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'stanford', download: 'stanford')
      end
    end

    context 'when stanford (no-download)' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <group rule="no-download">stanford</group>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'stanford', download: 'none')
      end
    end

    context 'when stanford + world (no-download)' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <group>stanford</group>
            </machine>
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'world', download: 'stanford')
      end
    end

    context 'when world' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <world/>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'world', download: 'world')
      end
    end

    context 'when world (no-download)' do
      let(:file_specific_rights) do
        <<~XML
          <access type="read">
            <file>gs491bt1345_sample_md.pdf</file>
            <machine>
              <world rule="no-download"/>
            </machine>
          </access>
        XML
      end

      it 'returns no access metadata for files without their own rights' do
        expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
      end

      it 'generates file-level access metadata for files with their own rights' do
        expect(text_fileset.pluck(:access)).to include(access: 'world', download: 'none')
      end
    end

    ['ars', 'art', 'hoover', 'm&m', 'music', 'spec'].each do |location|
      context "with location:#{location}" do
        let(:file_specific_rights) do
          <<~XML
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
              <machine>
                <location>#{CGI.escapeHTML(location)}</location>
              </machine>
            </access>
          XML
        end

        it 'returns no access metadata for files without their own rights' do
          expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
        end

        it 'generates file-level access metadata for files with their own rights' do
          expect(text_fileset.pluck(:access)).to include(access: 'location-based', download: 'location-based', readLocation: location)
        end
      end

      context "with location:#{location} (no-download)" do
        let(:file_specific_rights) do
          <<~XML
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
              <machine>
                <location rule="no-download">#{CGI.escapeHTML(location)}</location>
              </machine>
            </access>
          XML
        end

        it 'returns no access metadata for files without their own rights' do
          expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
        end

        it 'generates file-level access metadata for files with their own rights' do
          expect(text_fileset.pluck(:access)).to include(access: 'location-based', download: 'none', readLocation: location)
        end
      end

      context "with location:#{location} + stanford (no-download)" do
        let(:file_specific_rights) do
          <<~XML
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
              <machine>
                <location>#{CGI.escapeHTML(location)}</location>
              </machine>
              <machine>
                <group rule="no-download">stanford</group>
              </machine>
            </access>
          XML
        end

        it 'returns no access metadata for files without their own rights' do
          expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
        end

        it 'generates file-level access metadata for files with their own rights' do
          expect(text_fileset.pluck(:access)).to include(access: 'stanford', download: 'location-based', readLocation: location)
        end
      end

      context "with location:#{location} + world (no-download)" do
        let(:file_specific_rights) do
          <<~XML
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
              <machine>
                <location>#{CGI.escapeHTML(location)}</location>
              </machine>
              <machine>
                <world rule="no-download"/>
              </machine>
            </access>
          XML
        end

        it 'returns no access metadata for files without their own rights' do
          expect(audio_fileset.pluck(:access)).to all(eq(item_cocina_rights))
        end

        it 'generates file-level access metadata for files with their own rights' do
          expect(text_fileset.pluck(:access)).to include(access: 'world', download: 'location-based', readLocation: location)
        end
      end
    end
  end
end
