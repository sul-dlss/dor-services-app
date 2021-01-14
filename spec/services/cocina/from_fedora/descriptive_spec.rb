# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive do
  subject(:descriptive) do
    described_class.props(mods: Nokogiri::XML(desc_metadata), druid: 'druid:mj284jb0952', notifier: notifier)
  end

  let(:notifier) { instance_double(Cocina::FromFedora::DataErrorNotifier) }

  context 'when the item is a was-seed' do
    let(:desc_metadata) do
      <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.6" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        <titleInfo>
          <nonSort xml:space="preserve">The</nonSort>
          <title>IRA, social media and political polarization in the United States, 2012-2018</title>
        </titleInfo>






        <typeOfResource>text</typeOfResource>
        <genre authority="marcgt">bibliography</genre>
        <genre authority="rdacontent">text</genre>
        <originInfo>
          <place>
            <placeTerm type="code" authority="marccountry">enk</placeTerm>
          </place>
          <dateIssued encoding="marc">2018</dateIssued>
          <copyrightDate encoding="marc">2018</copyrightDate>
          <issuance>monographic</issuance>
        <dateCreated keyDate="yes" encoding="w3cdtf">2018-12</dateCreated></originInfo>
        <originInfo eventType="publication">
          <place>
            <placeTerm type="text">[Oxford, United Kingdom]</placeTerm>
          </place>
          <publisher>University of Oxford</publisher>
          <dateIssued>2018</dateIssued>
        </originInfo>
        <language>
          <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
        </language>
        <physicalDescription>
          <form authority="marccategory">electronic resource</form>
          <form authority="marcsmd">remote</form>
          <extent>1 online resource (46 pages) : color illustrations, color map</extent>
          <form type="media" authority="rdamedia">computer</form>
          <form type="carrier" authority="rdacarrier">online resource</form>
        </physicalDescription>
        <abstract displayLabel="Summary">Russia's Internet Research Agency (IRA) launched an extended attack on the United States by using computational propaganda to misinform and polarize US voters. This report provides the first major analysis of this attack based on data provided by social media firms to the Senate Select Committee on Intelligence (SSCI). This analysis answers several key questions about the activities of the known IRA accounts. In this analysis, we investigate how the IRA exploited the tools and platform of Facebook, Instagram, Twitter and YouTube to impact US users. We identify which aspects of the IRA's campaign strategy got the most traction on social media and the means of microtargeting US voters with particular messages.</abstract>
        <tableOfContents>Executive summary. -- Introduction: Rising IRA involvement in US politics. -- Data &amp; Methodology. -- Overview of IRA activity across platforms. -- RA acticity and key political events in the US. -- The IRA's advertising campaign against US voters. -- How the IRA targeted US audiences on Twitter. -- Engaging US voters with organic posts on Facebook and Instagram. -- Conclusion: IRA activity a political polarization in the US. -- References. -- Series acknowlegements. -- Author biographies.</tableOfContents>
        <note type="statement of responsibility">Philip N. Howard, Bharath Ganesh, Dimitra Liotsiou, John Kelly, Camille Fran&#xE7;ois.</note>
        <note>At head of title: Computational Propaganda Research Project.</note>
        <note type="bibliography">Includes bibliographical references (pages 42-43).</note>
        <subject>
          <geographicCode authority="marcgac">e-ru---</geographicCode>
          <geographicCode authority="marcgac">n-us---</geographicCode>
        </subject>
        <subject authority="lcsh">

        </subject>
        <subject authority="lcsh">
          <titleInfo>
            <title>Facebook (Electronic resource)</title>
          </titleInfo>
          <topic>Political aspects</topic>
          <geographic>United States</geographic>
          <topic>Evaluation</topic>
        </subject>
        <subject authority="lcsh">
          <titleInfo>
            <title>Twitter</title>
          </titleInfo>
          <topic>Political aspects</topic>
          <geographic>United States</geographic>
          <topic>Evaluation</topic>
        </subject>
        <subject authority="lcsh">
          <titleInfo>
            <title>YouTube (Electronic resource)</title>
          </titleInfo>
          <topic>Political aspects</topic>
          <geographic>United States</geographic>
          <topic>Evaluation</topic>
        </subject>
        <subject authority="lcsh">
          <topic>Information warfare</topic>
          <geographic>Russia (Federation)</geographic>
        </subject>
        <subject authority="lcsh">
          <topic>Disinformation</topic>
          <geographic>Russia (Federation)</geographic>
        </subject>
        <subject authority="lcsh">
          <topic>Elections</topic>
          <geographic>United States</geographic>
        </subject>
        <subject authority="lcsh">
          <topic>Social media</topic>
          <topic>Political aspects</topic>
        </subject>
        <subject authority="lcsh">
          <topic>Online social networks</topic>
          <topic>Political aspects</topic>
        </subject>
        <subject authority="lcsh">
          <topic>Internet in political campaigns</topic>
          <geographic>United States</geographic>
        </subject>
        <subject authority="lcsh">
          <topic>Communication in politics</topic>
          <geographic>United States</geographic>
        </subject>
        <subject>
          <topic>Instagram (Electronic resource)</topic>
          <topic>Political aspects</topic>
          <geographic>United States</geographic>
          <topic>Evaluation</topic>
        </subject>
        <subject authority="lcsh">
          <topic>Polarization (Social sciences)</topic>
        </subject>
        <location>
          <url displayLabel="electronic resource" usage="primary display">https://comprop.oii.ox.ac.uk/wp-content/uploads/sites/93/2018/12/IRA-Report-2018.pdf</url>
        </location>
        <location>
          <url displayLabel="electronic resource">https://purl.stanford.edu/tz346yg1321</url>
        </location>
        <identifier type="oclc">1079419321</identifier>
        <recordInfo>
          <descriptionStandard>rda</descriptionStandard>
          <recordContentSource authority="marcorg">DID</recordContentSource>
          <recordCreationDate encoding="marc">181219</recordCreationDate>
          <recordChangeDate encoding="iso8601">20181220093450.0</recordChangeDate>
          <recordIdentifier source="SIRSI">a12864684</recordIdentifier>
          <recordOrigin>Converted from MARCXML to MODS version 3.6 using MARC21slim2MODS3-6_SDR.xsl (SUL version 1 2018/06/13; LC Revision 1.118 2018/01/31)</recordOrigin>
          <languageOfCataloging>
            <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
          </languageOfCataloging>
        </recordInfo>
      <relatedItem><titleInfo><title>IRA, social media and political polarization in the United States, 2012-2018 (Computational Propaganda Project)</title></titleInfo><location><url>https://comprop.oii.ox.ac.uk/research/ira-political-polarization/</url></location></relatedItem><note type="contact">jrjacobs@stanford.edu</note><name type="personal"><namePart>Howard, Philip N</namePart><role><roleTerm authority="marcrelator" type="text">Author</roleTerm></role></name><name type="personal"><namePart>Ganesh, Bharath</namePart><role><roleTerm authority="marcrelator" type="text">Author</roleTerm></role></name><name type="personal"><namePart>Liotsiou, Dimitra</namePart><role><roleTerm authority="marcrelator" type="text">Author</roleTerm></role></name><name type="personal"><namePart>Kelly, John</namePart><role><roleTerm authority="marcrelator" type="text">Author</roleTerm></role></name><name type="personal"><namePart>Fran&#xE7;ois, Camille</namePart><role><roleTerm authority="marcrelator" type="text">Author</roleTerm></role></name><name type="corporate"><namePart>University of Oxford</namePart><role><roleTerm authority="marcrelator" type="text">Publisher</roleTerm></role></name><name type="corporate"><namePart>Internet Research Agency, LLC.</namePart><role><roleTerm authority="marcrelator" type="text">Publisher</roleTerm></role></name><note type="preferred citation"/></mods>
      XML
    end

    it 'has a url' do
      expect(descriptive[:purl]).to eq('https://purl.stanford.edu/bb196dd3409')
      expect(descriptive[:note]).to match_array [
        {
          value: 'http://ennejah.info/',
          type: 'system details',
          displayLabel: 'Original site'
        },
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
          value: 'Site closed after 2010.'
        },
        {
          value: 'Archived by Stanford University Libraries, Humanities and Area Studies Resource Group'
        },
        {
          value: 'California Digital Library Web Archiving Service',
          displayLabel: 'Web archiving service'
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
      expect(descriptive[:contributor]).to match_array [{
        name: [{
          value: 'Stanford University. Libraries. Humanities and Area Studies Resource Group'
        }],
        type: 'organization',
        role: [{
          value: 'collector',
          code: 'col',
          uri: 'http://id.loc.gov/vocabulary/relators/col',
          source: {
            code: 'marcrelator',
            uri: 'http://id.loc.gov/vocabulary/relators/'
          }
        }]
      }, {
        name: [{
          value: 'Joe McNopart'
        }]
      }]
      expect(descriptive[:form]).to match_array [
        { source: { value: 'MODS resource types' }, type: 'resource type', value: 'text' },
        { source: { code: 'local' }, type: 'genre', value: 'archived website' },
        {
          value: 'electronic',
          type: 'form',
          source: {
            code: 'marcform'
          }
        },
        { value: 'text/html', type: 'media type', source: { value: 'IANA media types' } },
        { value: 'born digital', type: 'digital origin', source: { value: 'MODS digital origin terms' } }
      ]
      expect(descriptive[:subject].size).to eq 2
    end
  end

  context 'when the item is an ETD' do
    let(:desc_metadata) do
      <<~XML
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
            <form type="technique">estampe</form>
            <form type="material">eau-forte</form>
            <form type="material">gravure au pointill&#xE9;</form>
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
          value: 'Blah blah blah, I believe in science!',
          displayLabel: 'Abstract'
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
          name: [{
            value: 'Doe, John Jr.'
          }],
          type: 'person',
          status: 'primary',
          role: [{
            value: 'author'
          }]
        },
        {
          name: [{
            value: 'Doe, John Sr.'
          }],
          type: 'person',
          role: [
            { value: 'degree supervisor' },
            {
              code: 'ths',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          ]
        },
        {
          name: [{
            value: 'Doe, Jane'
          }],
          type: 'person',
          role: [
            { value: 'degree committee member' },
            {
              code: 'ths',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          ]
        },
        {
          name: [{
            value: 'Majors, Brad'
          }],
          type: 'person',
          role: [
            { value: 'degree committee member' },
            {
              code: 'ths',
              source: {
                code: 'marcrelator',
                uri: 'http://id.loc.gov/vocabulary/relators/'
              }
            }
          ]
        },
        {
          name: [{
            structuredValue: [
              { value: 'Stanford University' },
              { value: 'Department of Computer Science.' }
            ]
          }],
          type: 'organization'
        }
      ]
      expect(descriptive[:form]).to match_array [
        { source: { code: 'marcgt' }, type: 'genre', value: 'theses' },
        { source: { code: 'rdacontent' }, type: 'genre', value: 'text' },
        { source: { value: 'MODS resource types' }, type: 'resource type', value: 'text' },
        {
          value: 'electronic resource',
          type: 'form',
          source: {
            code: 'marccategory'
          }
        },
        {
          value: 'remote',
          type: 'form',
          source: {
            code: 'marcsmd'
          }
        },
        {
          value: 'computer',
          type: 'media',
          source: {
            code: 'rdamedia'
          }
        },
        {
          value: 'online resource',
          type: 'carrier',
          source: {
            code: 'rdacarrier'
          }
        },
        { value: '1 online resource.', type: 'extent' },
        { value: 'estampe', type: 'technique' },
        { value: 'eau-forte', type: 'material' },
        { value: 'gravure au pointillé', type: 'material' }
      ]
    end
  end

  context 'when altRepGroup have different lang' do
    let(:desc_metadata) do
      <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <titleInfo usage="primary" lang="fre" altRepGroup="0">
            <title>Les misérables</title>
          </titleInfo>
          <titleInfo type="translated" lang="eng" altRepGroup="0">
            <title>The wretched</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'does not warn' do
      descriptive
    end
  end

  context 'when altRepGroup have different script' do
    let(:desc_metadata) do
      <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <titleInfo usage="primary" lang="rus" script="Cyrl" altRepGroup="0">
            <title>Война и миръ</title>
          </titleInfo>
          <titleInfo type="translated" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="0">
            <title>Voĭna i mir</title>
          </titleInfo>
        </mods>
      XML
    end

    it 'does not warn' do
      descriptive
    end
  end

  context 'when altRepGroup without lang or script' do
    let(:desc_metadata) do
      <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <titleInfo usage="primary" altRepGroup="0">
            <title>Война и миръ</title>
          </titleInfo>
          <titleInfo type="translated" transliteration="ALA-LC Romanization Tables" altRepGroup="0">
            <title>Voĭna i mir</title>
          </titleInfo>
        </mods>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'warns' do
      descriptive
      expect(notifier).to have_received(:warn).with('Bad altRepGroup')
    end
  end

  context 'when altRepGroup with same lang and script' do
    let(:desc_metadata) do
      <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <titleInfo usage="primary" lang="rus" script="Latn" altRepGroup="0">
            <title>Война и миръ</title>
          </titleInfo>
          <titleInfo type="translated" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables" altRepGroup="0">
            <title>Voĭna i mir</title>
          </titleInfo>
        </mods>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'warns' do
      descriptive
      expect(notifier).to have_received(:warn).with('Bad altRepGroup')
    end
  end

  context 'when altRepGroup have different tags' do
    let(:desc_metadata) do
      <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns="http://www.loc.gov/mods/v3" version="3.5" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-5.xsd">
          <titleInfo usage="primary" lang="rus" script="Cyrl" altRepGroup="0">
            <title>Война и миръ</title>
          </titleInfo>
          <name type="personal" usage="primary" lang="rus" script="Latn" altRepGroup="0">
            <namePart>Dunnett, Dorothy</namePart>
          </name>
        </mods>
      XML
    end

    before do
      allow(notifier).to receive(:warn)
    end

    it 'warns' do
      descriptive
      expect(notifier).to have_received(:warn).with('Bad altRepGroup')
    end
  end
end
