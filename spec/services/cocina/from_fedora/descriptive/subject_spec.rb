# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Subject do
  subject(:build) { described_class.build(resource_element: ng_xml.root, descriptive_builder: descriptive_builder) }

  let(:descriptive_builder) { Cocina::FromFedora::Descriptive::DescriptiveBuilder.new(notifier: notifier) }

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with invalid subelement <Topic>' do
    let(:xml) do
      <<~XML
        <subject authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <Topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure (as if it was <topic> lowercase) and warns' do
      expect(build).to eq [
        {
          value: 'College students',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85028356',
          source: {
            uri: 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('<subject> has <Topic>; normalized to "topic"')
    end
  end

  context 'with invalid authority code and an authorityURI' do
    let(:xml) do
      <<~XML
        <subject authority="topic" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'includes the invalid code and warns' do
      expect(build).to eq [
        {
          value: 'College students',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85028356',
          source: {
            uri: 'http://id.loc.gov/authorities/subjects/',
            code: 'topic'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('Subject has unknown authority code', { code: 'topic' })
    end
  end

  context 'with tgm authority code' do
    let(:xml) do
      <<~XML
        <subject authority="tgm" authorityURI="http://id.loc.gov/vocabulary/graphicMaterials" valueURI="http://id.loc.gov/vocabulary/graphicMaterials/tgm001818">
          <topic>Celebrities</topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'changes to lctgm and warns' do
      expect(build).to eq [
        {
          value: 'Celebrities',
          type: 'topic',
          uri: 'http://id.loc.gov/vocabulary/graphicMaterials/tgm001818',
          source: {
            code: 'lctgm',
            uri: 'http://id.loc.gov/vocabulary/graphicMaterials'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('tgm authority code (should be lctgm)')
    end
  end

  context 'with invalid authority code and no authorityURI' do
    let(:xml) do
      <<~XML
        <subject authority="topic" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'includes source and warns' do
      expect(build).to eq [
        {
          value: 'College students',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85028356',
          source: {
            code: 'topic'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('Subject has unknown authority code', { code: 'topic' })
    end
  end

  context 'with lcnaf authority code' do
    let(:xml) do
      <<~XML
        <subject authority="lcnaf" valueURI="http://id.loc.gov/authorities/subjects/sh85028356">
          <topic>College students</Topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'changes to naf and warns' do
      expect(build).to eq [
        {
          value: 'College students',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85028356',
          source: {
            code: 'naf'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('lcnaf authority code')
    end
  end

  context 'with a single invalid subelement <corporate>' do
    let(:xml) do
      <<~XML
        <subject>
          <corporate>Some bogus value for this bogus element</corporate>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'does not build subject element at all' do
      expect(build).to eq []
      expect(notifier).to have_received(:warn).with('Unexpected node type for subject', { name: 'corporate' })
    end
  end

  context 'with a valid element plus an invalid subelement <corporate>' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <corporate>Some bogus value for this bogus element</corporate>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'drops the invalid subelement and warns' do
      expect(build).to eq [
        {
          structuredValue: [
            {
              value: 'Cats',
              type: 'topic'
            }
          ]
        }
      ]
      expect(notifier).to have_received(:warn).with('Unexpected node type for subject', { name: 'corporate' })
    end
  end

  context 'with multiple valid element plus an invalid subelement <corporate>' do
    let(:xml) do
      <<~XML
        <subject>
          <topic>Cats</topic>
          <topic>Dogs</topic>
          <corporate>Some bogus value for this bogus element</corporate>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'drops the invalid subelement and warns' do
      expect(build).to eq [
        {
          structuredValue: [
            {
              value: 'Cats',
              type: 'topic'
            },
            {
              value: 'Dogs',
              type: 'topic'
            }
          ]
        }
      ]
      expect(notifier).to have_received(:warn).with('Unexpected node type for subject', { name: 'corporate' })
    end
  end

  context 'with a single-term topic subject with authority on the subject and authorityURI and valueURI on topic' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <topic authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          value: 'Cats',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
          source: {
            code: 'lcsh',
            uri: 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
    end
  end

  context 'with a single-term topic subject with non-lcsh authority on the subject' do
    let(:xml) do
      <<~XML
        <subject authority="mesh">
          <topic>Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          value: 'Cats',
          type: 'topic',
          source: {
            code: 'mesh'
          }
        }
      ]
    end
  end

  context 'with invalid subject "#N/A" authority' do
    let(:xml) do
      <<~XML
        <subject authority="#N/A">
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        {
          value: 'Cats',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
          source: {
            code: 'lcsh',
            uri: 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
      expect(notifier).to have_received(:warn).with('"#N/A" authority code')
    end
  end

  context 'with a single-term topic subject with authority on the topic' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh">
          <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          value: 'Cats',
          type: 'topic',
          uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
          source: {
            code: 'lcsh',
            uri: 'http://id.loc.gov/authorities/subjects/'
          }
        }
      ]
    end
  end

  # Example 19c
  context 'with a multilingual subject but no lang attributes' do
    let(:xml) do
      <<~XML
        <subject altRepGroup="1">
          <cartographics>
            <scale>Scale 1:650,000.</scale>
          </cartographics>
        </subject>
        <subject altRepGroup="1">
          <cartographics>
            <scale>&#x6BD4;&#x4F8B;&#x5C3A; 1:650,000.</scale>
          </cartographics>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq []
    end
  end

  context 'with a cartographic subject missing coordinates' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <scale>1:22,000,000</scale>
            <projection>Conic proj</projection>
          </cartographics>
        </subject>
      XML
    end

    it 'builds (empty) cocina data structure' do
      expect(build).to eq []
    end
  end

  context 'with multiple subjects with cartographics, some with separate cartographics for scale vs coordinates' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <coordinates>W0750700 W0741200 N0443400 N0431200</coordinates>
          </cartographics>
        </subject>
        <subject>
          <cartographics>
            <scale>Scale ca. 1:126,720. 1 in. to 2 miles.</scale>
          </cartographics>
          <cartographics>
            <coordinates>(W 75&#x2070;07&#x2B9;00&#x2B9;--W 74&#x2070;12&#x2B9;00&#x2B9;/N 44&#x2070;34&#x2B9;00&#x2B9;--N 43&#x2070;12&#x2B9;00&#x2B9;)</coordinates>
          </cartographics>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          type: 'map coordinates',
          value: 'W0750700 W0741200 N0443400 N0431200'
        },
        {
          type: 'map coordinates',
          value: 'W 75⁰07ʹ00ʹ--W 74⁰12ʹ00ʹ/N 44⁰34ʹ00ʹ--N 43⁰12ʹ00ʹ'
        }
      ]
    end
  end

  context 'with single subject with multiple cartographics, none with coordinates' do
    let(:xml) do
      <<~XML
        <subject>
          <cartographics>
            <scale>Scale 1:100,000 :</scale>
          </cartographics>
          <cartographics>
            <projection>universal transverse Mercator proj.</projection>
          </cartographics>
        </subject>
      XML
    end

    it 'builds (empty) cocina data structure' do
      expect(build).to eq []
    end
  end

  context 'with a ISO19115TopicCategory subject' do
    let(:xml) do
      <<~XML
        <subject>
         <topic authority="ISO19115TopicCategory"
            authorityURI="http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode" valueURI="farming">Farming</topic>
        </subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and warns' do
      expect(build).to eq [
        {
          source: {
            code: 'ISO19115TopicCategory',
            uri: 'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode'
          },
          uri: 'farming',
          value: 'Farming',
          type: 'topic'
        }
      ]
      expect(notifier).to have_received(:warn).with('Value URI has unexpected value', { uri: 'farming' })
    end
  end

  context 'with a parallel subject but different types' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85135212" altRepGroup="2">
          <geographic>Tiber River (Italy)</geographic>
        </subject>
        <subject authority="local" altRepGroup="2">
          <topic>Tevere</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          parallelValue: [
            {
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              },
              uri: 'http://id.loc.gov/authorities/subjects/sh85135212',
              value: 'Tiber River (Italy)',
              type: 'place'
            },
            {
              source: {
                code: 'local'
              },
              value: 'Tevere',
              type: 'topic'
            }
          ]
        }
      ]
    end
  end

  context 'with a subject with lang, script, and displayLabel' do
    let(:xml) do
      <<~XML
        <subject lang="fre" script="Latn" displayLabel="French archives">
          <topic>Archives et documents</topic>
          <topic>Portraits</topic>
        </subject>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          structuredValue: [
            {
              value: 'Archives et documents',
              type: 'topic'
            },
            {
              value: 'Portraits',
              type: 'topic'
            }
          ],
          valueLanguage: {
            code: 'fre',
            source: {
              code: 'iso639-2b'
            },
            valueScript: {
              code: 'Latn',
              source: {
                code: 'iso15924'
              }
            }
          },
          displayLabel: 'French archives'
        }
      ]
    end
  end

  # From druid:rv133bz1764
  context 'with a bad subject' do
    let(:xml) do
      <<~XML
        <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh2002009897">authority="" authorityURI="" valueURI=""&gt;Improvisation (Acting)</subject>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'builds the cocina data structure and errors' do
      expect(build).to eq [
        {
          source: {
            code: 'lcsh',
            uri: 'http://id.loc.gov/authorities/subjects/'
          },
          uri: 'http://id.loc.gov/authorities/subjects/sh2002009897'
        }
      ]
      expect(notifier).to have_received(:warn).with('Subject has text',
                                                    { subject: '<subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" ' \
                                                               'valueURI="http://id.loc.gov/authorities/subjects/sh2002009897">authority="" ' \
                                                               'authorityURI="" valueURI=""&gt;Improvisation (Acting)</subject>' })
    end
  end
end
