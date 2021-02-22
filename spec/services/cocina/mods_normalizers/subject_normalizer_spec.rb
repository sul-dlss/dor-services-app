# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizers::SubjectNormalizer do
  let(:normalized_ng_xml) { Cocina::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: nil, label: nil).to_xml }

  context 'when normalizing topic' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'moves authority, authorityURI, valueURI to topic' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="fast">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'leaves unchanges' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="fast">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing topic with authority on subject and authorityURI and valueURI on topic' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="fast">
            <topic authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'adds authority to topic' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="local">
            <topic authority="local">Big Game</topic>
          </subject>
        </mods>
      XML
    end

    it 'removes authority from topic' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="local">
            <topic>Big Game</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject with authority and authorityURI only for lcsh' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects">
            <geographic authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n78089021">Japan</geographic>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects" valueURI="http://id.loc.gov/authorities/subjects/sh99001269">Maps</topic>
          </subject>
        </mods>
      XML
    end

    it 'removes authorityURI from subject' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <geographic authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n78089021">Japan</geographic>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh99001269">Maps</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject with authority and authorityURI only' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="fast" authorityURI="http://id.worldcat.org/fast/">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009448">Marine paleontology</topic>
          </subject>
        </mods>
      XML
    end

    it 'removes authorityURI from subject' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="fast">
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009447">Marine biology</topic>
            <topic authority="fast" authorityURI="http://id.worldcat.org/fast/" valueURI="http://id.worldcat.org/fast/1009448">Marine paleontology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing name subject with authority only' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject>
            <name type="personal" authority="local">
              <namePart>Hugo, Victor (Venezuelan, c. 1942-1993)</namePart>
            </name>
          </subject>
        </mods>
      XML
    end

    it 'moves to subject' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="local">
            <name type="personal">
              <namePart>Hugo, Victor (Venezuelan, c. 1942-1993)</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject with authority on children but not subject' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh86007360">Non-governmental organizations</topic>
            <geographic authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79091151">China</geographic>
          </subject>
        </mods>
      XML
    end

    it 'moves to subject' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh86007360">Non-governmental organizations</topic>
            <geographic authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79091151">China</geographic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject with naf authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="naf" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n79055384">
            <name type="corporate">
              <namePart>Princeton University</namePart>
            </name>
          </subject>
        </mods>
      XML
    end

    it 'moves to name' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <name authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n79055384" type="corporate">
              <namePart>Princeton University</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing topic with additional term' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85046193">Excavations (Archaeology)</topic>
            <geographic>Turkey</geographic>
          </subject>
        </mods>
      XML
    end

    it 'leaves unchanged' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85046193">Excavations (Archaeology)</topic>
            <geographic>Turkey</geographic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject with authority and authorityURI, but not on children' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects">
          <geographic>Tel Aviv (Israel)</geographic>
            <topic>Politics and government</topic>
          </subject>
        </mods>
      XML
    end

    it 'leaves unchanged' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/">
          <geographic>Tel Aviv (Israel)</geographic>
            <topic>Politics and government</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing normalized_ng_xml name' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85005490">
            <geographic>Antarctica</geographic>
          </subject>
        </mods>
      XML
    end

    it 'moves authority, authorityURI, valueURI to geographic' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
          <mods #{MODS_ATTRIBUTES}>
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
          <mods #{MODS_ATTRIBUTES}>
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
          <mods #{MODS_ATTRIBUTES}>
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
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="naf">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes naf to lcsh' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <name type="corporate" authority="naf" authorityURI="http://id.loc.gov/authorities/names/" valueURI="http://id.loc.gov/authorities/names/n80034013">
              <namePart>Institute for the Future</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing lcnaf subject authority' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lcsh">
            <topic authority="lcnaf">Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes lcnaf to naf' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="tgm">
            <topic authority="tgm">Marine biology</topic>
          </subject>
        </mods>
      XML
    end

    it 'changes tgm to lctgm' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="lctgm">
            <topic>Marine biology</topic>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing cartographic coordinates' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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

  context 'when normalizing lang and script' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject>
            <name type="personal" lang="chi" script="Hant">
              <namePart>汪精衛, 1883-1944</namePart>
            </name>
          </subject>
        </mods>
      XML
    end

    it 'moves to subject' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject lang="chi" script="Hant">
            <name type="personal">
              <namePart>汪精衛, 1883-1944</namePart>
            </name>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing temporal' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject>
            <temporal encoding="iso8601" point="start">[1923?-]</temporal>
            <temporal encoding="iso8601" point="end"/>
          </subject>
          <subject>
            <temporal />
          </subject>
        </mods>
      XML
    end

    it 'removes empty' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject>
            <temporal encoding="iso8601" point="start">[1923?-]</temporal>
          </subject>
        </mods>
      XML
    end
  end

  context 'when normalizing empty geographic' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="geonames" authorityURI="http://sws.geonames.org" valueURI="http://sws.geonames.org/2946447/">
            <geographic/>
          </subject>
          <subject>
            <geographic/>
          </subject>
          <subject>
            <geographic valueURI="http://sws.geonames.org/5391295"/>
          </subject>
        </mods>
      XML
    end

    it 'removes empty' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <subject authority="geonames" authorityURI="http://sws.geonames.org" valueURI="http://sws.geonames.org/2946447/" />
          <subject>
            <geographic valueURI="http://sws.geonames.org/5391295"/>
          </subject>
        </mods>
      XML
    end
  end
end
