# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(mods_ng_xml: mods_ng_xml, druid: druid) }

  let(:druid) { 'druid:pf694bk4862' }

  context 'when normalizing version' do
    context 'when version in recordInfo' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.7"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
            <recordInfo>
              <recordOrigin>Converted from MARCXML to MODS version 3.7 using MARC21slim2MODS3-6_SDR.xsl (SUL version 1 2018/06/13; LC Revision 1.118 2018/01/31)</recordOrigin>
            </recordInfo>
          </mods>
        XML
      end

      it 'leaves version' do
        expect(normalized_ng_xml.root['version']).to eq('3.7')
        expect(normalized_ng_xml.root['xsi:schemaLocation']).to eq('http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd')
      end
    end

    context 'when version not in recordInfo' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
            xmlns="http://www.loc.gov/mods/v3" version="3.7"
            xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
          </mods>
        XML
      end

      it 'changes version to 3.7' do
        expect(normalized_ng_xml.root['version']).to eq('3.7')
        expect(normalized_ng_xml.root['xsi:schemaLocation']).to eq('http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd')
      end
    end
  end

  context 'when normalizing PURL' do
    let(:druid) { 'druid:bw502ns3302' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <relatedItem>
            <location>
              <url>http://purl.stanford.edu/vt726fn1198</url>
            </location>
          </relatedItem>
        </mods>
      XML
    end

    it 'adds usage' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url usage="primary display">http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <relatedItem>
            <location>
              <url usage="primary display">http://purl.stanford.edu/vt726fn1198</url>
            </location>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL but existing primary display in same <location> node' do
    let(:druid) { 'druid:bw502ns3302' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
            <url usage="primary display">http://www.stanford.edu</url>
          </location>
        </mods>
      XML
    end

    it 'moves primary display' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url usage="primary display">http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <location>
            <url>http://www.stanford.edu</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL but existing primary display in different <location> node' do
    let(:druid) { 'druid:bw502ns3302' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <location>
            <url usage="primary display" note="Available to Stanford-affiliated users at READEX:">http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
        </mods>
      XML
    end

    it 'moves primary display' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url usage="primary display">http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <location>
            <url note="Available to Stanford-affiliated users at READEX:">http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing relatedType with type and otherType' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <relatedItem type="otherFormat" otherType="Online version:" displayLabel="Online version:">
            <titleInfo>
              <title>Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften. Mathematisch-Naturwissenschaftliche Classe. Abt. 2, Mathematik, Physik, Chemie, Physiologie, Meteorologie, physische Geographie und Astronomie</title>
            </titleInfo>
            <identifier type="local">(OCoLC)606338944</identifier>
          </relatedItem>
        </mods>
      XML
    end

    it 'does not add otherType' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <relatedItem type="otherFormat" displayLabel="Online version:">
            <titleInfo>
              <title>Sitzungsberichte der Kaiserlichen Akademie der Wissenschaften. Mathematisch-Naturwissenschaftliche Classe. Abt. 2, Mathematik, Physik, Chemie, Physiologie, Meteorologie, physische Geographie und Astronomie</title>
            </titleInfo>
            <identifier type="local">(OCoLC)606338944</identifier>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when normalizing empty notes' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <note type="statement of responsibility" altRepGroup="00" script="Latn"/>
          <note>Includes various issues of some sheets.</note>
        </mods>
      XML
    end

    it 'removes' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <note>Includes various issues of some sheets.</note>
        </mods>
      XML
    end
  end

  context 'when normalizing unmatches altRepGroups' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject altRepGroup='1'>
            <topic>Marine biology</topic>
          </subject>
          <subject altRepGroup='1'>
            <topic>Biología marina</topic>
          </subject>
          <subject altRepGroup='2'>
            <topic>Vulcanology</topic>
          </subject>
        </mods>
      XML
    end

    it 'removes unmatched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject altRepGroup='1'>
            <topic>Marine biology</topic>
          </subject>
          <subject altRepGroup='1'>
            <topic>Biología marina</topic>
          </subject>
          <subject>
            <topic>Vulcanology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing unmatches nameTitleGroups' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo usage="primary" nameTitleGroup="1">
            <title>Slaughterhouse-Five</title>
          </titleInfo>
          <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="0">
            <title>Hamlet</title>
          </titleInfo>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="0">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="3">
            <namePart>Vonnegut, Kurt</namePart>
          </name>
        </mods>
      XML
    end

    it 'removes unmatched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo usage="primary">
            <title>Slaughterhouse-Five</title>
          </titleInfo>
          <titleInfo type="uniform" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80008522" nameTitleGroup="0">
            <title>Hamlet</title>
          </titleInfo>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332" nameTitleGroup="0">
            <namePart>Shakespeare, William, 1564-1616</namePart>
          </name>
          <name usage="primary" type="personal" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78095332">
            <namePart>Vonnegut, Kurt</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when normalizing empty attributes' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <classification authority="">Y 1.1/2:</mods:classification>
        </mods>
      XML
    end

    it 'removes unmatched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <classification>Y 1.1/2:</mods:classification>
        </mods>
      XML
    end
  end

  context 'when normalizing xml:space' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <nonSort xml:space="preserve">The</nonSort>
            <title>registers of the parish church of Adel, in the county of York, from 1606 to 1812</title>
            <subTitle>and monumental inscriptions</subTitle>
          </titleInfo>
        </mods>
      XML
    end

    it 'removes xml:space' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <titleInfo>
            <nonSort>The</nonSort>
            <title>registers of the parish church of Adel, in the county of York, from 1606 to 1812</title>
            <subTitle>and monumental inscriptions</subTitle>
          </titleInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing languageTerm types' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <recordInfo>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        </mods>
      XML
    end

    it 'removes unmatched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <recordInfo>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing restriction on access without spaces' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <accessCondition type="restrictionOnAccess">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end

    it 'adds spaces' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when normalizing restriction on use and reproduction without spaces' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <accessCondition type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</accessCondition>
        </mods>
      XML
    end

    it 'adds spaces' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <accessCondition type="use and reproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when normalizing identifiers' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <identifier type="Isbn">1234 5678 9203</identifier>
          <identifier type="Ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
          <identifier type="Oclc">123456789203</identifier>
          <identifier type="Xyz">123456789203</identifier>
          <identifier type="stock number">123456789203</identifier>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
            <nameIdentifier type="iSbn">1234 5678 9203</identifier>
            <nameIdentifier type="aRk">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
            <nameIdentifier type="oClc">123456789203</identifier>
            <nameIdentifier type="xYz">123456789203</identifier>
          </name>
          <recordInfo>
            <recordIdentifier source="isBn">1234 5678 9203</identifier>
            <recordIdentifier source="arK">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
            <recordIdentifier source="ocLc">123456789203</identifier>
            <recordIdentifier source="xyZ">123456789203</identifier>
          </recordInfo>
        </mods>
      XML
    end

    it 'fixes capitalization' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <identifier type="isbn">1234 5678 9203</identifier>
          <identifier type="ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
          <identifier type="OCLC">123456789203</identifier>
          <identifier type="Xyz">123456789203</identifier>
          <identifier type="stock-number">123456789203</identifier>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
            <nameIdentifier type="isbn">1234 5678 9203</identifier>
            <nameIdentifier type="ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
            <nameIdentifier type="OCLC">123456789203</identifier>
            <nameIdentifier type="xYz">123456789203</identifier>
          </name>
          <recordInfo>
            <recordIdentifier source="isbn">1234 5678 9203</identifier>
            <recordIdentifier source="ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
            <recordIdentifier source="OCLC">123456789203</identifier>
            <recordIdentifier source="xyZ">123456789203</identifier>
          </recordInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing physical location purl' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url usage="primary display">http://purl.stanford.edu/cy979mw6316</url>
            <physicalLocation>Stanford University Libraries</physicalLocation>
            <shelfLocator>Who Wants Shelves</shelfLocator>
          </location>
          <relatedItem>
            <location>
              <url usage="primary display">http://purl.stanford.edu/fy479mw7313</url>
              <physicalLocation>Palo Alto Public Library</physicalLocation>
              <shelfLocator>I Wants Shelves</shelfLocator>
            </location>
          </relatedItem>
        </mods>
      XML
    end

    it 'combines the location blocks' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <location>
            <url usage="primary display">http://purl.stanford.edu/cy979mw6316</url>
          </location>
          <location>
            <physicalLocation>Stanford University Libraries</physicalLocation>
          </location>
          <location>
            <shelfLocator>Who Wants Shelves</shelfLocator>
          </location>
          <relatedItem>
            <location>
              <url usage="primary display">http://purl.stanford.edu/fy479mw7313</url>
            </location>
            <location>
              <physicalLocation>Palo Alto Public Library</physicalLocation>
            </location>
            <location>
              <shelfLocator>I Wants Shelves</shelfLocator>
            </location>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when normalizing empty relatedItem parts' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Social sciences &amp; humanities index</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number/>
              </detail>
            </part>
          </relatedItem>
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>STEM index</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number>2</number>
              </detail>
            </part>
          </relatedItem>
        </mods>
      XML
    end

    it 'removes part' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>Social sciences &amp; humanities index</title>
            </titleInfo>
          </relatedItem>
          <relatedItem type="isReferencedBy">
            <titleInfo>
              <title>STEM index</title>
            </titleInfo>
            <part>
              <detail type="part">
                <number>2</number>
              </detail>
            </part>
          </relatedItem>
        </mods>
      XML
    end
  end

  context 'when normalizing empty relatedItem' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <relatedItem />
        </mods>
      XML
    end

    it 'removes relatedItem' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
        </mods>
      XML
    end
  end

  context 'when normalizing abstract summary' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <abstract type="summary">This is a summary.</abstract>
        </mods>
      XML
    end

    it 'removes attribute' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <abstract>This is a summary.</abstract>
        </mods>
      XML
    end
  end
end
