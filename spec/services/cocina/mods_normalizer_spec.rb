# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(mods_ng_xml: mods_ng_xml, druid: druid) }

  let(:mods_attributes) do
    'xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.6"
    xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd"'
  end
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

      it 'changes version to 3.6' do
        expect(normalized_ng_xml.root['version']).to eq('3.6')
        expect(normalized_ng_xml.root['xsi:schemaLocation']).to eq('http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd')
      end
    end
  end

  context 'when normalizing subject' do
    context 'when normalizing topic' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">
              <topic>Marine biology</topic>
            </subject>
          </mods>
        XML
      end

      it 'moves authority, authorityURI, valueURI to topic' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject authority="fast">
              <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing topic with authority on subject and topic' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject authority="fast">
              <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
            </subject>
          </mods>
        XML
      end

      it 'leaves unchanges' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject authority="fast">
              <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing topic with authority only' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject authority="local">
              <topic authority="local">Big Game</topic>
            </subject>
          </mods>
        XML
      end

      it 'removes authority from topic' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject authority="local">
              <topic>Big Game</topic>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing topic with additional term' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject authority="lcsh">
              <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85046193">Excavations (Archaeology)</topic>
              <geographic>Turkey</geographic>
            </subject>
          </mods>
        XML
      end

      it 'leaves unchanged' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject authority="lcsh">
              <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85046193">Excavations (Archaeology)</topic>
              <geographic>Turkey</geographic>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing normalized_ng_xml name' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">
              <name type="personal">
                <namePart>Anning, Mary, 1799-1847</namePart>
              </name>
            </subject>
          </mods>
        XML
      end

      it 'moves authority, authorityURI, valueURI to topic' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject authority="fast">
              <name type="personal" authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">
                <namePart>Anning, Mary, 1799-1847</namePart>
              </name>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing authorityURIs' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <name authorityURI="http://id.loc.gov/authorities/names">
              <namePart authorityURI="http://id.loc.gov/authorities/subjects">Anning, Mary, 1799-1847</namePart>
              <role>
                <roleTerm authority="marcrelator" type="text" authorityURI="http://id.loc.gov/vocabulary/relators">creator</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end

      it 'adds trailing slash' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <name authorityURI="http://id.loc.gov/authorities/names/">
              <namePart authorityURI="http://id.loc.gov/authorities/subjects/">Anning, Mary, 1799-1847</namePart>
              <role>
                <roleTerm authority="marcrelator" type="text" authorityURI="http://id.loc.gov/vocabulary/relators/">creator</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when normalizing geographic' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">
              <geographic>Antarctica</geographic>
            </subject>
          </mods>
        XML
      end

      it 'moves authority, authorityURI, valueURI to geographic' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject authority="lcsh">
              <geographic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">Antarctica</geographic>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing multiple cartographics' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <subject>
              <cartographics>
                <scale>Scale 1:100,000 :</scale>
              </cartographics>
              <cartographics>
                <projection>universal transverse Mercator proj.</projection>
              </cartographics>
            </subject>
          </mods>
        XML
      end

      it 'combines multiple elements into a single one' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <subject>
              <cartographics>
                <scale>Scale 1:100,000 :</scale>
                <projection>universal transverse Mercator proj.</projection>
              </cartographics>
            </subject>
          </mods>
        XML
      end
    end

    context 'when normalizing single cartographics' do
      context 'with child nodes' do
        let(:mods_ng_xml) do
          Nokogiri::XML <<~XML
            <mods #{mods_attributes}>
              <subject>
                <cartographics>
                  <scale>Scale 1:100,000 :</scale>
                  <projection>universal transverse Mercator proj.</projection>
                </cartographics>
              </subject>
            </mods>
          XML
        end

        it 'returns the single node' do
          expect(normalized_ng_xml).to be_equivalent_to <<~XML
            <mods #{mods_attributes}>
              <subject>
                <cartographics>
                  <scale>Scale 1:100,000 :</scale>
                  <projection>universal transverse Mercator proj.</projection>
                </cartographics>
              </subject>
            </mods>
          XML
        end
      end

      context 'with empty child nodes' do
        let(:mods_ng_xml) do
          Nokogiri::XML <<~XML
            <mods #{mods_attributes}>
              <subject>
                <cartographics>
                  <scale/>
                </cartographics>
              </subject>
            </mods>
          XML
        end

        it 'removes the empty node' do
          expect(normalized_ng_xml).to be_equivalent_to <<~XML
            <mods #{mods_attributes}>
            </mods>
          XML
        end
      end
    end
  end

  context 'when normalizing originInfo eventTypes' do
    context 'when event type assigning date element present' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <originInfo>
              <dateIssued>1930</dateIssued>
            </originInfo>
            <originInfo>
              <copyrightDate>1931</copyrightDate>
            </originInfo>
            <originInfo>
              <dateCreated>1932</dateCreated>
            </originInfo>
            <relatedItem>
              <originInfo>
                <dateCaptured>1932</dateCaptured>
              </originInfo>
            </relatedItem>
          </mods>
        XML
      end

      it 'adds eventType if missing' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <originInfo eventType="publication">
              <dateIssued>1930</dateIssued>
            </originInfo>
            <originInfo eventType="copyright notice">
              <copyrightDate>1931</copyrightDate>
            </originInfo>
            <originInfo eventType="production">
              <dateCreated>1932</dateCreated>
            </originInfo>
            <relatedItem>
              <originInfo eventType="capture">
                <dateCaptured>1932</dateCaptured>
              </originInfo>
            </relatedItem>
          </mods>
        XML
      end
    end

    context 'when no event type assigning date element is present' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <originInfo>
              <publisher>Macro Hamster Press</publisher>
            </originInfo>
            <relatedItem type="otherFormat">
              <originInfo>
                <publisher>Northwestern University Library</publisher>
              </originInfo>
            </relatedItem>
            <relatedItem type="otherFormat">
              <originInfo>
                <edition>Euro-global ed.</edition>
              </originInfo>
            </relatedItem>
          </mods>
        XML
      end

      it 'adds eventType if missing' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <originInfo eventType="publication">
              <publisher>Macro Hamster Press</publisher>
            </originInfo>
            <relatedItem type="otherFormat">
              <originInfo eventType="publication">
                <publisher>Northwestern University Library</publisher>
              </originInfo>
            </relatedItem>
            <relatedItem type="otherFormat">
              <originInfo eventType="publication">
                <edition>Euro-global ed.</edition>
              </originInfo>
            </relatedItem>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing originInfo dateOther[@type]' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <originInfo eventType="distribution">
            <dateOther type="distribution"/>
          </originInfo>
          <originInfo eventType="manufacture">
            <dateOther type="manufacture"/>
          </originInfo>
          <originInfo eventType="distribution">
            <dateOther type="distribution">1937</dateOther>
          </originInfo>
        </mods>
      XML
    end

    it 'removes dateOther type attribute if it matches eventType and dateOther is empty' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo eventType="distribution">
            <dateOther/>
          </originInfo>
          <originInfo eventType="manufacture">
            <dateOther/>
          </originInfo>
          <originInfo eventType="distribution">
            <dateOther type="distribution">1937</dateOther>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfo/place/placeTerm text values' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <originInfo eventType="production" displayLabel="Place of Creation">
            <place supplied="yes">
              <placeTerm authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79118971">Oakland (Calif.)</placeTerm>
            </place>
          </originInfo>
          <originInfo eventType="publication" displayLabel="publisher">
            <place>
              <placeTerm>[Stanford, California] :</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end

    it 'adds type text attribute if appropriate' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo eventType="production" displayLabel="Place of Creation">
            <place supplied="yes">
              <placeTerm type="text" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79118971">Oakland (Calif.)</placeTerm>
            </place>
          </originInfo>
          <originInfo eventType="publication" displayLabel="publisher">
            <place>
              <placeTerm type="text">[Stanford, California] :</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject authority="naf">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes naf to lcsh' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject authority="lcsh">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing text roleTerm' do
    context 'when the content has capital letters' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">pht</roleTerm>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">Photographer</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end

      it 'downcases text' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">pht</roleTerm>
                <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">photographer</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end

    context 'when the role term has no type' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm>photographer</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end

      it 'add type="text"' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <name>
              <namePart>Dunnett, Dorothy</namePart>
              <role>
                <roleTerm type="text">photographer</roleTerm>
              </role>
            </name>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing roleTerm authorityURI' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">pht</roleTerm>
              <roleTerm type="text" authority="marcrelator" valueURI="http://id.loc.gov/vocabulary/relators/pht">Photographer</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end

    it 'adds authorityURI' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <name>
            <namePart>Dunnett, Dorothy</namePart>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">pht</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">photographer</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL' do
    let(:druid) { 'druid:bw502ns3302' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
        </mods>
      XML
    end

    it 'adds usage' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <location>
            <url usage="primary display">http://purl.stanford.edu/bw502ns3302</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL but existing primary display in same <location> node' do
    let(:druid) { 'druid:bw502ns3302' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
            <url usage="primary display">http://www.stanford.edu</url>
          </location>
        </mods>
      XML
    end

    it 'does not add usage' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <location>
            <url usage="primary display">http://www.stanford.edu</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL but existing primary display in different <location> node' do
    let(:druid) { 'druid:bw502ns3302' }

    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <location>
            <url usage="primary display" note="Available to Stanford-affiliated users at READEX:">http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
        </mods>
      XML
    end

    it 'does not add usage' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
          <location>
            <url usage="primary display" note="Available to Stanford-affiliated users at READEX:">http://infoweb.newsbank.com/?db=SERIAL</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing relatedItem with single PURL location/url' do
    context 'when normalizing PURL' do
      let(:druid) { 'druid:bw502ns3302' }

      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes}>
            <relatedItem type="otherVersion" displayLabel="Associated Essay">
              <titleInfo>
                <title>essay68buildingGrandCanyonPart3fredHarveyCo.pdf</title>
              </titleInfo>
              <location>
                <url>http://purl.stanford.edu/bw502ns3302</url>
              </location>
            </relatedItem>
          </mods>
        XML
      end

      it 'adds usage' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes}>
            <relatedItem type="otherVersion" displayLabel="Associated Essay">
              <titleInfo>
                <title>essay68buildingGrandCanyonPart3fredHarveyCo.pdf</title>
              </titleInfo>
              <location>
                <url usage="primary display">http://purl.stanford.edu/bw502ns3302</url>
              </location>
            </relatedItem>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing relatedItem with type and otherType' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
          <note type="statement of responsibility" altRepGroup="00" script="Latn"/>
          <note>Includes various issues of some sheets.</note>
        </mods>
      XML
    end

    it 'removes' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <note>Includes various issues of some sheets.</note>
        </mods>
      XML
    end
  end

  context 'when normalizing unmatches altRepGroups' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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

  context 'when normalizing empty attributes' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <classification authority="">Y 1.1/2:</mods:classification>
        </mods>
      XML
    end

    it 'removes unmatched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <classification>Y 1.1/2:</mods:classification>
        </mods>
      XML
    end
  end

  context 'when normalizing xml:space' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
          <recordInfo>
            <languageOfCataloging>
              <languageTerm authority="iso639-2b" type="code">eng</languageTerm>
            </languageOfCataloging>
          </recordInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject>
            <name type="personal" authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">
              <namePart>Anning, Mary, 1799-1847</namePart>
            </name>
          </subject>
        </mods>
      XML
    end

    it 'adds authority' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject authority="fast">
            <name type="personal" authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/270223">
              <namePart>Anning, Mary, 1799-1847</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject authority when child authority is naf' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject>
            <name type="corporate" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80034013">
              <namePart>Institute for the Future</namePart>
            </name>
          </subject>
        </mods>
      XML
    end

    it 'adds lcsh authority' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject authority="lcsh">
            <name type="corporate" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80034013">
              <namePart>Institute for the Future</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject authority with geographicCode child' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject>
            <geographicCode authority="marcgac">n-us-md</geographicCode>
          </subject>
        </mods>
      XML
    end

    it 'does not add authority' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject>
            <geographicCode authority="marcgac">n-us-md</geographicCode>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing geo PURL' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="https://www.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
        </mods>
      XML
    end

    it 'uses correct PURL' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
        </mods>
      XML
    end
  end

  context 'when normalizing missing geo PURL' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description>
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
        </mods>
      XML
    end

    it 'adds correct PURL' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
          <extension displayLabel="geo">
            <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
              <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                <dc:format>image/jpeg</dc:format>
                <dc:type>Image</dc:type>
              </rdf:Description>
            </rdf:RDF>
          </extension>
        </mods>
      XML
    end
  end

  context 'when normalizing restriction on access without spaces' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <accessCondition type="restrictionOnAccess">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end

    it 'adds spaces' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when normalizing restriction on use and reproduction without spaces' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <accessCondition type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</accessCondition>
        </mods>
      XML
    end

    it 'adds spaces' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <accessCondition type="use and reproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when normalizing identifiers' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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

  context 'when normalizing lcnaf subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject authority="lcsh">
            <topic authority="lcnaf">Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes lcnaf to naf' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject authority="lcsh">
            <topic authority="naf">Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing tgm subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject authority="tgm">
            <topic authority="tgm">Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes tgm to lctgm' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject authority="lctgm">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing physical location purl' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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

  context 'when normalizing dc:type image' do
    context 'when image (lowercase I)' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="https://www.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
          </mods>
        XML
      end

      it 'fix capitalization (capitalizes I)' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>Image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
          </mods>
        XML
      end
    end

    context 'when Image (uppercase I)' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="https://www.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>Image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
          </mods>
        XML
      end

      it 'leaves capitalization' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{mods_attributes} xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
            <extension displayLabel="geo">
              <rdf:RDF xmlns:gml="http://www.opengis.net/gml/3.2/" xmlns:dc="http://purl.org/dc/elements/1.1/">
                <rdf:Description rdf:about="http://purl.stanford.edu/pf694bk4862">
                  <dc:format>image/jpeg</dc:format>
                  <dc:type>Image</dc:type>
                </rdf:Description>
              </rdf:RDF>
            </extension>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing empty relatedItem parts' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        <mods #{mods_attributes}>
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

  context 'when normalizing empty names' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <name>
            <namePart/>
            <role>
              <roleTerm authority="marcrelator" type="text">author</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end

    it 'removes name' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
        </mods>
      XML
    end
  end

  context 'when name has xlink:href' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes} xmlns:xlink="http://www.w3.org/1999/xlink">
          <name type="personal" authority="naf" xlink:href="http://id.loc.gov/authorities/names/n82087745">
            <namePart>Tirion, Isaak</namePart>
          </name>
        </mods>
      XML
    end

    it 'is converted to valueURI' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <name type="personal" authority="naf" valueURI="http://id.loc.gov/authorities/names/n82087745">
            <namePart>Tirion, Isaak</namePart>
          </name>
        </mods>
      XML
    end
  end

  context 'when normalizing empty title' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <titleInfo>
            <title />
            <subTitle/>
          </titleInfo>
        </mods>
      XML
    end

    it 'removes titleInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
        </mods>
      XML
    end
  end

  context 'when normalizing empty relatedItem' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <relatedItem />
        </mods>
      XML
    end

    it 'removes relatedItem' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfo with developed date' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <originInfo displayLabel="Place of Creation" eventType="production">
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
            <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
          </originInfo>
        </mods>
      XML
    end

    it 'moves to own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo displayLabel="Place of Creation" eventType="production">
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
            <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
          </originInfo>
          <originInfo eventType="development">
            <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing parallel originInfos with no script or lang' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <originInfo altRepGroup="0203">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Chengdu</placeTerm>
            </place>
            <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
            <dateIssued>2005</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
            <frequency>Monthly</frequency>
          </originInfo>
          <originInfo altRepGroup="0203">
            <place>
              <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
            </place>
            <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
            <dateIssued>2005</dateIssued>
            <edition>[Di 1 ban in Chinese]</edition>
            <frequency authority=\"marcfrequency\">Monthly</frequency>
          </originInfo>
        </mods>
      XML
    end

    it 'adds other values to all originInfos in group' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo altRepGroup="0203" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Chengdu</placeTerm>
            </place>
            <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
            <dateIssued>2005</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
            <frequency>Monthly</frequency>
            <frequency authority=\"marcfrequency\">Monthly</frequency>
          </originInfo>
          <originInfo altRepGroup="0203" eventType="publication">
            <place>
              <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
            </place>
            <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
            <dateIssued>2005</dateIssued>
            <edition>[Di 1 ban in Chinese]</edition>
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <issuance>monographic</issuance>
            <frequency>Monthly</frequency>
            <frequency authority=\"marcfrequency\">Monthly</frequency>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing parallel originInfos with same script or lang' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <originInfo altRepGroup="0203" script="Latn">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Chengdu</placeTerm>
            </place>
            <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
            <dateIssued>2005</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
            <frequency>Monthly</frequency>
          </originInfo>
          <originInfo altRepGroup="0203" script="Latn">
            <place>
              <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
            </place>
            <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
            <dateIssued>2005</dateIssued>
            <edition>[Di 1 ban in Chinese]</edition>
            <frequency authority=\"marcfrequency\">Monthly</frequency>
          </originInfo>
        </mods>
      XML
    end

    it 'adds other values to all originInfos in group' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo altRepGroup="0203" eventType="publication" script="Latn">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Chengdu</placeTerm>
            </place>
            <publisher>Sichuan chu ban ji tuan, Sichuan wen yi chu ban she</publisher>
            <dateIssued>2005</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
            <frequency>Monthly</frequency>
            <frequency authority=\"marcfrequency\">Monthly</frequency>
          </originInfo>
          <originInfo altRepGroup="0203" eventType="publication" script="Latn">
            <place>
              <placeTerm type="text">[Chengdu in Chinese]</placeTerm>
            </place>
            <publisher>[Sichuan chu ban ji tuan, Sichuan wen yi chu ban she in Chinese]</publisher>
            <dateIssued>2005</dateIssued>
            <edition>[Di 1 ban in Chinese]</edition>
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <issuance>monographic</issuance>
            <frequency>Monthly</frequency>
            <frequency authority=\"marcfrequency\">Monthly</frequency>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfos with lang and scripts' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <originInfo script="Latn" lang="eng" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">ja</placeTerm>
            </place>
            <dateIssued encoding="marc" point="start">1915</dateIssued>
            <dateIssued encoding="marc" point="end">1942</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
        </mods>
      XML
    end

    it 'removes if none of the children are parallelizable' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">ja</placeTerm>
            </place>
            <dateIssued encoding="marc" point="start">1915</dateIssued>
            <dateIssued encoding="marc" point="end">1942</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfos with copyright dates' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
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
        </mods>
      XML
    end

    it 'moves copyright into its own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cau</placeTerm>
            </place>
            <dateIssued encoding="marc">2020</dateIssued>
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
            <copyrightDate encoding="marc">2020</copyrightDate>
          </originInfo>
          <originInfo eventType="copyright notice">
            <copyrightDate>&#xA9;2020</copyrightDate>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing cartographic coordinates' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject>
            <cartographics>
              <coordinates>(E 72°--E 148°/N 13°--N 18°)</coordinates>
              <scale>1:22,000,000</scale>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end

    it 'removes parentheses' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject>
            <cartographics>
              <coordinates>E 72°--E 148°/N 13°--N 18°</coordinates>
              <scale>1:22,000,000</scale>
              <projection>Conic proj</projection>
            </cartographics>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing multiple cartographic subjects' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{mods_attributes}>
          <subject>
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>Custom projection</projection>
              <coordinates>(E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ)</coordinates>
            </cartographics>
          </subject>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326" displayLabel="WGS84">
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>EPSG::4326</projection>
              <coordinates>E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
            </cartographics>
          </subject>
          <relatedItem>
            <subject>
              <cartographics>
                <scale>Scale given.</scale>
                <projection>Custom projection</projection>
                <coordinates>W 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
              </cartographics>
            </subject>
          </relatedItem>
        </mods>
      XML
    end

    it 'puts all subject/cartographics without authority together' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{mods_attributes}>
          <subject authority="EPSG" valueURI="http://opengis.net/def/crs/EPSG/0/4326" displayLabel="WGS84">
            <cartographics>
              <projection>EPSG::4326</projection>
            </cartographics>
          </subject>
          <subject>
            <cartographics>
              <scale>Scale not given.</scale>
              <projection>Custom projection</projection>
              <coordinates>E 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
            </cartographics>
          </subject>
          <relatedItem>
            <subject>
              <cartographics>
                <scale>Scale given.</scale>
                <projection>Custom projection</projection>
                <coordinates>W 72°34ʹ58ʺ--E 73°52ʹ24ʺ/S 52°54ʹ8ʺ--S 53°11ʹ42ʺ</coordinates>
              </cartographics>
            </subject>
          </relatedItem>
        </mods>
      XML
    end
  end
end
