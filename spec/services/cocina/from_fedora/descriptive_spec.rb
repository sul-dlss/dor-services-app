# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive do
  subject(:descriptive) { described_class.props(item) }

  let(:item) do
    Dor::Item.new
  end

  context 'when the item is a was-seed' do
    before do
      item.descMetadata.content = <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <titleInfo>
            <title>Messaoud Ould Boulkheir - Mauritania 2009 Presidential Election</title>
          </titleInfo>
          <name type="corporate">
            <namePart>Stanford University. Libraries. Humanities and Area Studies Resource Group</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/col">col</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators" valueURI="http://id.loc.gov/vocabulary/relators/col">collector</roleTerm>
            </role>
          </name>
          <typeOfResource>text</typeOfResource>
          <genre authority="local">archived website</genre>
          <language>
            <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara" type="code">ara</languageTerm>
            <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/ara" type="text">Arabic</languageTerm>
          </language>
          <language>
            <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/fre" type="code">fre</languageTerm>
            <languageTerm authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/fre" type="text">French</languageTerm>
          </language>
          <physicalDescription>
            <form authority="marcform">electronic</form>
            <digitalOrigin>born digital</digitalOrigin>
            <internetMediaType>text/html</internetMediaType>
          </physicalDescription>
          <abstract>Official site of opposition candidate Boulkheir, "the Mauritanian Obama," for the 2009 Mauritania presidential election. The election was held July 18, 2009. Boulkheir came in second place with 16.3 percent of the vote. Elected "Pr&#xE9;sident de l&#x2019;Assembl&#xE9;e Nationale" in 2007. Boulkheir also had 5 Facebook pages including "SOUTENONS TOUS LE CANDIDAT OFFICIEL DU FNDD: MESS3OUD 0ULD BOULKHEIR" and "mess3oud ould belkhier LE CANDIDAT DU FNDD ET LE NOTRE VOTONS POUR LUI".</abstract>
          <note type="system details" displayLabel="Original site">http://ennejah.info/</note>
          <note>Site closed after 2010.</note>
          <note>Archived by Stanford University Libraries, Humanities and Area Studies Resource Group</note>
          <note displayLabel="Web archiving service">California Digital Library Web Archiving Service</note>
          <subject authority="local">
            <topic>Mauritania Presidential Election 2009</topic>
          </subject>
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh85041557">Elections</topic>
            <geographic authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n79061287">Mauritania</geographic>
          </subject>
          <location>
            <physicalLocation type="repository" authority="naf" valueURI="http://id.loc.gov/authorities/names/n81070667">Stanford University. Libraries</physicalLocation>
            <url usage="primary display">https://purl.stanford.edu/bb196dd3409</url>
            <url displayLabel="Archived website">https://swap.stanford.edu/*/http://ennejah.info/</url>
          </location>
          <recordInfo>
            <languageOfCataloging usage="primary">
              <languageTerm type="text" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">English</languageTerm>
              <languageTerm type="code" authority="iso639-2b" authorityURI="http://id.loc.gov/vocabulary/iso639-2" valueURI="http://id.loc.gov/vocabulary/iso639-2/eng">eng</languageTerm>
              <scriptTerm type="text" authority="iso15924">Latin</scriptTerm>
              <scriptTerm type="code" authority="iso15924">Latn</scriptTerm>
            </languageOfCataloging>
            <recordContentSource authority="marcorg" authorityURI="http://id.loc.gov/vocabulary/organizations" valueURI="http://id.loc.gov/vocabulary/organizations/cst">CSt</recordContentSource>
          </recordInfo>
        </mods>
      XML
    end

    it 'has a url' do
      expect(descriptive[:note]).to match_array [
        {
          type: 'summary',
          value: 'Official site of opposition candidate Boulkheir, "the Mauritanian Obama," ' \
          'for the 2009 Mauritania presidential election. The election was held July 18, 2009. ' \
          'Boulkheir came in second place with 16.3 percent of the vote. Elected ' \
          '"Président de l’Assemblée Nationale" in 2007. Boulkheir also had 5 Facebook pages including ' \
          '"SOUTENONS TOUS LE CANDIDAT OFFICIEL DU FNDD: MESS3OUD 0ULD BOULKHEIR" and ' \
          '"mess3oud ould belkhier LE CANDIDAT DU FNDD ET LE NOTRE VOTONS POUR LUI".'
        },
        {
          value: 'http://ennejah.info/',
          type: 'system details'
        }
      ]
      expect(descriptive[:language]).to match_array [
        {
          value: 'Arabic',
          code: 'ara',
          uri: 'http://id.loc.gov/vocabulary/iso639-2/ara',
          source: {
            code: 'iso639-2b',
            uri: 'http://id.loc.gov/vocabulary/iso639-2'
          }
        },
        {
          value: 'French',
          code: 'fre',
          uri: 'http://id.loc.gov/vocabulary/iso639-2/fre',
          source: {
            code: 'iso639-2b',
            uri: 'http://id.loc.gov/vocabulary/iso639-2'
          }
        }
      ]
      expect(descriptive[:contributor]).to match_array [
        name: {
          value: 'Stanford University. Libraries. Humanities and Area Studies Resource Group'
        },
        type: 'corporate'
      ]
      expect(descriptive[:form]).to match_array [
        {
          value: 'electronic',
          source: {
            code: 'marcform'
          }
        }
      ]
    end
  end

  context 'when the item is an ETD' do
    before do
      item.descMetadata.content = <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <titleInfo>
            <title>A Totally Ficticious Dissertation</title>
          </titleInfo>
          <name type="personal" usage="primary">
            <namePart>Doe, John Jr.</namePart>
            <role>
              <roleTerm type="text">author</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Doe, John Sr.</namePart>
            <role>
              <roleTerm type="text">degree supervisor</roleTerm>
            </role>
            <role>
              <roleTerm authority="marcrelator" type="code">ths</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Doe, Jane</namePart>
            <role>
              <roleTerm type="text">degree committee member</roleTerm>
            </role>
            <role>
              <roleTerm authority="marcrelator" type="code">ths</roleTerm>
            </role>
          </name>
          <name type="personal">
            <namePart>Majors, Brad</namePart>
            <role>
              <roleTerm type="text">degree committee member</roleTerm>
            </role>
            <role>
              <roleTerm authority="marcrelator" type="code">ths</roleTerm>
            </role>
          </name>
          <name type="corporate">
            <namePart>Stanford University</namePart>
            <namePart>Department of Computer Science.</namePart>
          </name>
          <typeOfResource>text</typeOfResource>
          <genre authority="marcgt">theses</genre>
          <genre authority="rdacontent">text</genre>
          <originInfo>
            <place>
              <placeTerm type="code" authority="marccountry">cau</placeTerm>
            </place>
            <dateIssued encoding="marc">2020</dateIssued>
            <copyrightDate encoding="marc">2020</copyrightDate>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">[Stanford, California]</placeTerm>
            </place>
            <publisher>[Stanford University]</publisher>
            <dateIssued>2020</dateIssued>
          </originInfo>
          <originInfo eventType="copyright notice">
            <copyrightDate>&#xA9;2020</copyrightDate>
          </originInfo>
          <language>
            <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
          </language>
          <physicalDescription>
            <form authority="marccategory">electronic resource</form>
            <form authority="marcsmd">remote</form>
            <extent>1 online resource.</extent>
            <form type="media" authority="rdamedia">computer</form>
            <form type="carrier" authority="rdacarrier">online resource</form>
          </physicalDescription>
          <abstract displayLabel="Abstract">Blah blah blah, I believe in science!</abstract>
          <note type="statement of responsibility">John Doe Jr.</note>
          <note>Submitted to the Department of Computer Science.</note>
          <note type="thesis">Thesis Ph.D. Stanford University 2020.</note>
          <location>
            <url displayLabel="electronic resource" usage="primary display">http://purl.stanford.edu/ab123dc1234</url>
          </location>
          <recordInfo>
            <descriptionStandard>rda</descriptionStandard>
            <recordContentSource authority="marcorg">CSt</recordContentSource>
            <recordCreationDate encoding="marc">200312</recordCreationDate>
            <recordIdentifier source="SIRSI">a13500152</recordIdentifier>
            <recordOrigin>Converted from MARCXML to MODS version 3.6 using MARC21slim2MODS3-6_SDR.xsl (SUL version 1 2018/06/13; LC Revision 1.118 2018/01/31)</recordOrigin>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        </mods>
      XML
    end

    it 'has a url' do
      expect(descriptive[:note]).to match_array [
        {
          type: 'summary',
          value: 'Blah blah blah, I believe in science!'
        },
        {
          value: 'John Doe Jr.',
          type: 'statement of responsibility'
        },
        {
          value: 'Thesis Ph.D. Stanford University 2020.',
          type: 'thesis'
        },
        {
          value: 'Submitted to the Department of Computer Science.'
        }
      ]
      expect(descriptive[:language]).to match_array [
        {
          code: 'eng',
          source: {
            code: 'iso639-2b'
          }
        }
      ]
      expect(descriptive[:contributor]).to match_array [
        {
          name: {
            value: 'Doe, John Jr.'
          },
          type: 'personal',
          status: 'primary',
          role: [{
            value: 'author'
          }]
        },
        {
          name: {
            value: 'Doe, John Sr.'
          },
          type: 'personal',
          role: [{
            value: 'degree supervisor',
            code: 'ths',
            source: {
              code: 'marcrelator'
            }
          }]
        },
        {
          name: {
            value: 'Doe, Jane'
          },
          type: 'personal',
          role: [{
            value: 'degree committee member',
            code: 'ths',
            source: {
              code: 'marcrelator'
            }
          }]
        },
        {
          name: {
            value: 'Majors, Brad'
          },
          type: 'personal',
          role: [{
            value: 'degree committee member',
            code: 'ths',
            source: {
              code: 'marcrelator'
            }
          }]
        },
        {
          name: {
            value: 'Stanford University'
          },
          type: 'corporate'
        }
      ]
      expect(descriptive[:form]).to match_array [
        {
          value: 'electronic resource',
          source: {
            code: 'marccategory'
          }
        },
        {
          value: 'remote',
          source: {
            code: 'marcsmd'
          }
        },
        {
          value: 'computer',
          source: {
            code: 'rdamedia'
          }
        },
        {
          value: 'online resource',
          source: {
            code: 'rdacarrier'
          }
        },
        { value: '1 online resource.', type: 'extent' }
      ]
    end
  end
end
