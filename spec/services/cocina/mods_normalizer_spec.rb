# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(mods_ng_xml) }

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
          <originInfo>
            <dateCaptured>1932</dateCaptured>
          </originInfo>
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
          <originInfo eventType="capture">
            <dateCaptured>1932</dateCaptured>
          </originInfo>
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

  context 'when normalizing PURL but existing primary display' do
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
end
