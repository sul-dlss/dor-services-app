# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToXml::AccessGenerator do
  subject(:generate) do
    Nokogiri::XML(described_class.generate(root:, access:, structural:))
  end

  let(:root) { Nokogiri::XML("<rightsMetadata>#{rights_statements}</rightsMetadata>").root }

  let(:access) { Cocina::Models::DROAccess.new(JSON.parse(cocina_access)) }

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
  let(:structural) { nil }

  describe 'object-level generation' do
    context 'when citation-only' do
      let(:cocina_access) do
        <<~JSON
          {
            "view": "citation-only",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "stanford",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "dark",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "stanford",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "stanford",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "world",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "world",
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
      let(:cocina_access) do
        <<~JSON
          {
            "view": "world",
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
        let(:cocina_access) do
          <<~JSON
            {
              "view": "location-based",
              "download": "location-based",
              "location": "#{location}"
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
        let(:cocina_access) do
          <<~JSON
            {
              "view": "location-based",
              "download": "none",
              "location": "#{location}"
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
        let(:cocina_access) do
          <<~JSON
            {
              "view": "stanford",
              "download": "location-based",
              "location": "#{location}"
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
        let(:cocina_access) do
          <<~JSON
            {
              "view": "world",
              "download": "location-based",
              "location": "#{location}"
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

  describe 'file rights generation' do
    let(:cocina_access) do
      <<~JSON
        {
          "view": "world",
          "download": "world"
        }
      JSON
    end
    # NOTE: We could test this with smaller filesets but it seemed wise to test
    #       with multiple sets containing multiple files
    let(:cocina_filesets) do
      <<~JSON
        [
          {
            "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/c8fc22e3-ba0b-4532-8536-f010d117415d",
            "type": "#{Cocina::Models::FileSetType.audio}",
            "version": 1,
            "structural": {
              "contains": [
                {
                  "externalIdentifier": "https://cocina.sul.stanford.edu/file/260a7c04-be8f-43cb-a1ae-2c6082563daf",
                  "type": "#{Cocina::Models::ObjectType.file}",
                  "label": "gs491bt1345_sample_01_00_pm.wav",
                  "filename": "gs491bt1345_sample_01_00_pm.wav",
                  "size": 299569842,
                  "version": 1,
                  "hasMessageDigests": [
                    {
                      "type": "sha1",
                      "digest": "ccde1331b5bc6c3dce0231c352c7a11f1fd3e77f"
                    },
                    {
                      "type": "md5",
                      "digest": "d46055f03b4a9dc30fcfdfebea473127"
                    }
                  ],
                  "access": {
                    "view": "world",
                    "download": "world"
                  },
                  "administrative": {
                    "publish": false,
                    "sdrPreserve": true,
                    "shelve": false
                  },
                  "hasMimeType": "audio/x-wav"
                },
                {
                  "externalIdentifier": "https://cocina.sul.stanford.edu/file/7420f933-5be0-4462-bbe0-d2f8ddba08e1",
                  "type": "#{Cocina::Models::ObjectType.file}",
                  "label": "gs491bt1345_sample_01_00_sh.wav",
                  "filename": "gs491bt1345_sample_01_00_sh.wav",
                  "size": 91743738,
                  "version": 1,
                  "hasMessageDigests": [
                    {
                      "type": "sha1",
                      "digest": "a9cb4668c42c5416a301759ff40fe365ea2467a3"
                    },
                    {
                      "type": "md5",
                      "digest": "188c0c972bc039c679bf984e75c7500e"
                    }
                  ],
                  "access": {
                    "view": "world",
                    "download": "world"
                  },
                  "administrative": {
                    "publish": false,
                    "sdrPreserve": true,
                    "shelve": false
                  },
                  "hasMimeType": "audio/x-wav"
                },
                {
                  "externalIdentifier": "https://cocina.sul.stanford.edu/file/70c2f617-1235-46a4-a015-ab788a4847ee",
                  "type": "#{Cocina::Models::ObjectType.file}",
                  "label": "gs491bt1345_sample_01_00_sl.m4a",
                  "filename": "gs491bt1345_sample_01_00_sl.m4a",
                  "size": 16798755,
                  "version": 1,
                  "hasMessageDigests": [
                    {
                      "type": "sha1",
                      "digest": "8d95b3b77f900b6d229ee32d05f927d75cbce032"
                    },
                    {
                      "type": "md5",
                      "digest": "b044b593d0d444180e82de064594339a"
                    }
                  ],
                  "access": {
                    "view": "world",
                    "download": "world"
                  },
                  "administrative": {
                    "publish": true,
                    "sdrPreserve": true,
                    "shelve": true
                  },
                  "hasMimeType": "audio/mp4"
                }
              ]
            },
           "label": "Audio file"
          },
          {
            "externalIdentifier": "https://cocina.sul.stanford.edu/fileSet/91df0a5b-093b-458e-a30a-9874a57d8313",
            "type": "#{Cocina::Models::FileSetType.file}",
            "version": 1,
            "structural": {
              "contains": [
                {
                  "externalIdentifier": "https://cocina.sul.stanford.edu/file/3be6c06c-453d-4291-ae44-59cec2da33e1",
                  "type": "#{Cocina::Models::ObjectType.file}",
                  "label": "gs491bt1345_sample_md.pdf",
                  "filename": "gs491bt1345_sample_md.pdf",
                  "size": 930089,
                  "version": 1,
                  "hasMessageDigests": [
                    {
                      "type": "sha1",
                      "digest": "3b342f7b87f126997088720c1220122d41c8c159"
                    },
                    {
                      "type": "md5",
                      "digest": "6ed0004f39657ff81dff7b2b017fb9d9"
                    }
                  ],
                  "access": #{cocina_file_access},
                  "administrative": {
                    "publish": true,
                    "sdrPreserve": true,
                    "shelve": true
                  },
                  "hasMimeType": "application/pdf"
                }
              ]
            },
            "label": "Program PDF"
          }
        ]
      JSON
    end
    let(:structural) { Cocina::Models::DROStructural.new(contains: JSON.parse(cocina_filesets)) }

    context 'when controlled digital lending' do
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "stanford",
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
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
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
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "dark",
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
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
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
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "stanford",
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
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
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
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "stanford",
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
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
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
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "world",
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
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
              <machine>
                <group>stanford</group>
              </machine>
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
      # NOTE: Added because when object and file accesses match, the file access is not inserted in the XML
      let(:cocina_access) do
        <<~JSON
          {
            "view": "stanford",
            "download": "stanford"
          }
        JSON
      end
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "world",
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
                <group>stanford</group>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_01_00_pm.wav</file>
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_01_00_sh.wav</file>
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_01_00_sl.m4a</file>
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
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
      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "world",
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
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_md.pdf</file>
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
      context "with location:#{location}" do
        let(:cocina_file_access) do
          <<~JSON
            {
              "view": "location-based",
              "download": "location-based",
              "location": "#{location}"
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
              <access type="read">
                <file>gs491bt1345_sample_md.pdf</file>
                <machine>
                  <location>#{CGI.escapeHTML(location)}</location>
                </machine>
              </access>
              #{rights_statements}
            </rightsMetadata>
          XML
        end
      end

      context "with location:#{location} (no-download)" do
        let(:cocina_file_access) do
          <<~JSON
            {
              "view": "location-based",
              "download": "none",
              "location": "#{location}"
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
              <access type="read">
                <file>gs491bt1345_sample_md.pdf</file>
                <machine>
                  <location rule="no-download">#{CGI.escapeHTML(location)}</location>
                </machine>
              </access>
              #{rights_statements}
            </rightsMetadata>
          XML
        end
      end

      context "with location:#{location} + stanford (no-download)" do
        let(:cocina_file_access) do
          <<~JSON
            {
              "view": "stanford",
              "download": "location-based",
              "location": "#{location}"
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
              <access type="read">
                <file>gs491bt1345_sample_md.pdf</file>
                <machine>
                  <location>#{CGI.escapeHTML(location)}</location>
                </machine>
                <machine>
                  <group rule="no-download">stanford</group>
                </machine>
              </access>
              #{rights_statements}
            </rightsMetadata>
          XML
        end
      end

      context "with location:#{location} + world (no-download)" do
        let(:cocina_file_access) do
          <<~JSON
            {
              "view": "world",
              "download": "location-based",
              "location": "#{location}"
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
              <access type="read">
                <file>gs491bt1345_sample_md.pdf</file>
                <machine>
                  <location>#{CGI.escapeHTML(location)}</location>
                </machine>
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

    context 'when citation-only' do
      let(:cocina_access) do
        <<~JSON
          {
            "view": "citation-only",
            "download": "none",
            "controlledDigitalLending": false
          }
        JSON
      end

      let(:cocina_file_access) do
        <<~JSON
          {
            "view": "dark",
            "download": "none",
            "controlledDigitalLending": false
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
            <access type="read">
              <file>gs491bt1345_sample_01_00_pm.wav</file>
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_01_00_sh.wav</file>
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <file>gs491bt1345_sample_01_00_sl.m4a</file>
              <machine>
                <world/>
              </machine>
            </access>
            #{rights_statements}
          </rightsMetadata>
        XML
      end
    end
  end
end
