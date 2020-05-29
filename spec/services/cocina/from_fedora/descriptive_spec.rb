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
    end
  end
end
