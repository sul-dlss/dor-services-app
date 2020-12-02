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

      it 'changes version to 3.6' do
        expect(normalized_ng_xml.root['version']).to eq('3.6')
        expect(normalized_ng_xml.root['xsi:schemaLocation']).to eq('http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd')
      end
    end
  end

  context 'when normalizing topic' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'moves authority, authorityURI, valueURI to topic' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="fast">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing topic with additional term' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85046193">Excavations (Archaeology)</topic>
            <geographic>Turkey</geographic>
          </subject>
        </mods>
      XML
    end

    it 'leaves unchanged' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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

  context 'when normalizing originInfo eventTypes' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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

  context 'when normalizing subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="naf">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes naf to lcsh' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject authority="lcsh">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing text roleTerm' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name>
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name>
            <role>
              <roleTerm type="code" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">pht</roleTerm>
              <roleTerm type="text" authority="marcrelator" authorityURI="http://id.loc.gov/vocabulary/relators/" valueURI="http://id.loc.gov/vocabulary/relators/pht">photographer</roleTerm>
            </role>
          </name>
        </mods>
      XML
    end
  end

  context 'when normalizing roleTerm authorityURI' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name>
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <name>
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
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
          </location>
        </mods>
      XML
    end

    it 'adds usage' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <url usage="primary display">http://purl.stanford.edu/bw502ns3302</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL but existing primary display in same <location> node' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
            <url usage="primary display">http://www.stanford.edu</url>
          </location>
        </mods>
      XML
    end

    it 'does not add usage' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <location>
            <url>http://purl.stanford.edu/bw502ns3302</url>
            <url usage="primary display">http://www.stanford.edu</url>
          </location>
        </mods>
      XML
    end
  end

  context 'when normalizing PURL but existing primary display in different <location> node' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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

  context 'when normalizing relatedType with type and otherType' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note type="statement of responsibility" altRepGroup="00" script="Latn"/>
          <note>Includes various issues of some sheets.</note>
        </mods>
      XML
    end

    it 'removes' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <note>Includes various issues of some sheets.</note>
        </mods>
      XML
    end
  end

  context 'when normalizing unmatches altRepGroups' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <classification authority="">Y 1.1/2:</mods:classification>
        </mods>
      XML
    end

    it 'removes unmatched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <classification>Y 1.1/2:</mods:classification>
        </mods>
      XML
    end
  end

  context 'when normalizing xml:space' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <subject>
            <geographicCode authority="marcgac">n-us-md</geographicCode>
          </subject>
        </mods>
      XML
    end

    it 'does not add authority' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3" version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          version="3.6"          
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
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
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="restrictionOnAccess">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end

    it 'adds spaces' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          version="3.6"          
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="restriction on access">Available to Stanford researchers only.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when normalizing restriction on use and reproduction without spaces' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="useAndReproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</accessCondition>
        </mods>
      XML
    end

    it 'adds spaces' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          version="3.6"          
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <accessCondition type="use and reproduction">User agrees that, where applicable, content will not be used to identify or to otherwise infringe the privacy or confidentiality rights of individuals. Content distributed via the Stanford Digital Repository may be subject to additional license and use restrictions applied by the depositor.</accessCondition>
        </mods>
      XML
    end
  end

  context 'when normalizing identifiers' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          version="3.6"
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <identifier type="Isbn">1234 5678 9203</identifier>
          <identifier type="Ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
          <identifier type="Oclc">123456789203</identifier>
          <identifier type="Xyz">123456789203</identifier>
          <identifier type="stock number">123456789203</identifier>
          <name>
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
        <?xml version="1.0"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xmlns="http://www.loc.gov/mods/v3"
          version="3.6"          
          xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
          <identifier type="isbn">1234 5678 9203</identifier>
          <identifier type="ark">http://bnf.fr/ark:/13030/tf5p30086k</identifier>
          <identifier type="OCLC">123456789203</identifier>
          <identifier type="Xyz">123456789203</identifier>
          <identifier type="stock-number">123456789203</identifier>
          <name>
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
end
