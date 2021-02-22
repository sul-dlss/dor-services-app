# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizers::OriginInfoNormalizer do
  let(:normalized_ng_xml) { Cocina::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: nil, label: nil).to_xml }

  context 'when normalizing originInfo eventTypes' do
    context 'when event type assigning date element present' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
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
              <dateValid>1933</dateValid>
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
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication">
              <dateIssued>1930</dateIssued>
            </originInfo>
            <originInfo eventType="copyright">
              <copyrightDate>1931</copyrightDate>
            </originInfo>
            <originInfo eventType="production">
              <dateCreated>1932</dateCreated>
            </originInfo>
            <originInfo eventType="validity">
              <dateValid>1933</dateValid>
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
          <mods #{MODS_ATTRIBUTES}>
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
          <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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

    # Temporarily ignoring <originInfo> pending https://github.com/sul-dlss/dor-services-app/issues/2128
    xit 'removes dateOther type attribute if it matches eventType and dateOther is empty' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="distribution"/>
          <originInfo eventType="manufacture"/>
          <originInfo eventType="distribution">
            <dateOther type="distribution">1937</dateOther>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfo date values' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <dateIssued>1930.</dateIssued>
          </originInfo>
          <originInfo eventType="copyright notice">
            <copyrightDate>1931.</copyrightDate>
          </originInfo>
          <originInfo eventType="production">
            <dateCreated>1932.</dateCreated>
          </originInfo>
          <originInfo eventType="capture">
            <dateCaptured>1933.</dateCaptured>
          </originInfo>
          <originInfo eventType="publication">
            <dateOther>1441.</dateOther>
          </originInfo>
          <originInfo eventType="validity">
            <dateValid>1934.</dateValid>
          </originInfo>
          <relatedItem>
            <originInfo eventType="capture">
              <dateCaptured>1932.</dateCaptured>
            </originInfo>
          </relatedItem>
        </mods>
      XML
    end

    it 'removes trailing period' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
            <dateCaptured>1933</dateCaptured>
          </originInfo>
          <originInfo eventType="publication">
            <dateOther>1441</dateOther>
          </originInfo>
          <originInfo eventType="validity">
            <dateValid>1934</dateValid>
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

  context 'when normalizing originInfo/place/placeTerm text values' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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

  context 'when normalizing originInfo with developed date' do
    context 'with unmatching eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
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
          <mods #{MODS_ATTRIBUTES}>
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

    context 'with matching eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo displayLabel="Place of Creation" eventType="production">
              <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
            </originInfo>
            <originInfo eventType="development">
              <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
            </originInfo>
          </mods>
        XML
      end

      it 'stays the same' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo displayLabel="Place of Creation" eventType="production">
              <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
            </originInfo>
            <originInfo eventType="development">
              <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'with no eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo displayLabel="Place of Creation">
              <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
              <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
            </originInfo>
          </mods>
        XML
      end

      it 'moves to own originInfo' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo displayLabel="Place of Creation" eventType="production">
              <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
            </originInfo>
            <originInfo eventType="development">
              <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
            </originInfo>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing parallel originInfos with no script or lang' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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

  context 'when normalizing originInfos with captured dates' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">tnu</placeTerm>
            </place>
            <dateIssued encoding="marc">2016</dateIssued>
            <dateCaptured encoding="iso8601" point="start">20141010</dateCaptured>
            <dateCaptured encoding="iso8601" point="end">20141012</dateCaptured>
            <issuance>monographic</issuance>
          </originInfo>
      XML
    end

    it 'moves copyright into its own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">tnu</placeTerm>
            </place>
            <dateIssued encoding="marc">2016</dateIssued>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo eventType="capture">
            <dateCaptured encoding="iso8601" point="start">20141010</dateCaptured>
            <dateCaptured encoding="iso8601" point="end">20141012</dateCaptured>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfos with copyright dates' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
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
        <mods #{MODS_ATTRIBUTES}>
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
          <originInfo eventType="copyright">
            <copyrightDate encoding="marc">2020</copyrightDate>
          </originInfo>
          <originInfo eventType="copyright notice">
            <copyrightDate>&#xA9;2020</copyrightDate>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing originInfos with copyright date and publisher' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="copyright notice">
            <publisher>Saturn Pictures</publisher>
            <copyrightDate>1971</copyrightDate>
          </originInfo>
      XML
    end

    it 'moves publisher into its own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="copyright notice">
            <copyrightDate>1971</copyrightDate>
          </originInfo>
          <originInfo eventType="publication">
            <publisher>Saturn Pictures</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when normalizing publisher' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <publisher lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables">Institut russkoĭ literatury (Pushkinskiĭ Dom)</publisher>
          </originInfo>
        </mods>
      XML
    end

    it 'moves lang, script, and transliteration to originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication" lang="rus" script="Latn" transliteration="ALA-LC Romanization Tables">
            <publisher>Institut russkoĭ literatury (Pushkinskiĭ Dom)</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when empty originInfo element' do
    context 'when no attributes no children' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo/>
          </mods>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when eventType attribute but no children' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication"/>
          </mods>
        XML
      end

      it 'does not remove it' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication"/>
          </mods>
        XML
      end
    end

    context 'when eventType attribute and (empty) child' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <publisher/>
            </originInfo>
          </mods>
        XML
      end

      # Temporarily ignoring <originInfo> pending https://github.com/sul-dlss/dor-services-app/issues/2128
      xit 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication"/>
          </mods>
        XML
      end
    end
  end

  describe 'empty originInfo date elements' do
    context 'when dateCreated' do
      # based on jw174hd9042, vy673zb2925
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateCreated></dateCreated>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateIssued' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateIssued/>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateIssued with encoding and type' do
      # based on vj932ns8042
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateIssued encoding="w3cdtf" keyDate="yes"/>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateCaptured' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateCaptured/>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateValid' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateValid></dateValid>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateModified' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateModified></dateModified>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateOther with no attibutes' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateOther></dateOther>
            </originInfo>
          </mods>
        XML
      end

      # Temporarily ignoring <originInfo> pending https://github.com/sul-dlss/dor-services-app/issues/2128
      xit 'removes the element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when dateOther with @type matching eventType' do
      # based on xv158sd4671, qx562pf7510
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateOther type="distribution"></dateOther>
            </originInfo>
          </mods>
        XML
      end

      # Temporarily ignoring <originInfo> pending https://github.com/sul-dlss/dor-services-app/issues/2128
      xit 'removes the element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when copyrightDate' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <copyrightDate></copyrightDate>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the empty child' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end
  end

  context 'when originInfo production followed by originInfo development' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of Creation" eventType="production">
            <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
          </originInfo>
          <originInfo eventType="development">
            <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
          </originInfo>
        </mods>
      XML
    end

    it 'stays the same' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of Creation" eventType="production">
            <dateCreated keyDate="yes" encoding="w3cdtf">2003-11-29</dateCreated>
          </originInfo>
          <originInfo eventType="development">
            <dateOther type="developed" encoding="w3cdtf">2003-12-01</dateOther>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when splitting originInfo dates into separate elements' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel='foo' eventType="publication">
            <dateIssued encoding="marc">2020</dateIssued>
            <copyrightDate encoding="marc">2020</copyrightDate>
            <copyrightDate>©2020</copyrightDate>
          </originInfo>
        </mods>
      XML
    end

    it 'includes displayLabel on both originInfo elements' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel='foo' eventType="publication">
            <dateIssued encoding="marc">2020</dateIssued>
          </originInfo>
          <originInfo displayLabel='foo' eventType="copyright">
            <copyrightDate encoding="marc">2020</copyrightDate>
            <copyrightDate>©2020</copyrightDate>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when dateCreated and dateIssued in eventType publication' do
    # based on kq506ht3416
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <publisher>Fontana/Collins</publisher>
            <dateIssued>1978</dateIssued>
            <dateCreated>(1981 printing)</dateCreated>
          </originInfo>
        </mods>
      XML
    end

    xit 'moves dateCreated into its own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <publisher>Fontana/Collins</publisher>
            <dateIssued>1978</dateIssued>
          </originInfo>
          <originInfo eventType="production">
            <dateCreated>(1981 printing)</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when dateCreated as point with 2 elements in same originInfo as dateIssued, dateIssued splits' do
    # based on nn349sf6895, rx731vv3403
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of creation" eventType="publication">
            <dateCreated keyDate="yes" encoding="w3cdtf" point="start">1872</dateCreated>
            <dateCreated encoding="w3cdtf" point="end">1885</dateCreated>
            <dateIssued>1887</dateIssued>
          </originInfo>
        </mods>
      XML
    end

    xit 'splits dateCreated and dateIssued into separate originInfo elements' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <dateIssued>1887</dateIssued>
          </originInfo>
          <originInfo displayLabel="Place of creation" eventType="production">
            <dateCreated keyDate="yes" encoding="w3cdtf" point="start">1872</dateCreated>
            <dateCreated encoding="w3cdtf" point="end">1885</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when dateCreated and dateIssued in same originInfo in altRepGroup' do
    # based on dz647hf2887, db936hw1344
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo altRepGroup="1" eventType="publication">
            <publisher>Tairyūsha</publisher>
            <dateIssued>Shōwa 52 [1977]</dateIssued>
            <dateCreated>(1978 printing)</dateCreated>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <publisher>泰流社</publisher>
            <dateIssued>昭和 52 [1977]</dateIssued>
            <dateCreated>(1978 printing)</dateCreated>
          </originInfo>
        </mods>
      XML
    end

    xit 'moves dateCreated into its own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="production">
             <dateCreated>(1978 printing)</dateCreated>
           </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <publisher>Tairyūsha</publisher>
            <dateIssued>Shōwa 52 [1977]</dateIssued>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <publisher>泰流社</publisher>
            <dateIssued>昭和 52 [1977]</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when dateCreated and dateOther in eventType production' do
    # based on dg875gq3366
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="something" eventType="production">
            <dateCreated keyDate="yes" encoding="w3cdtf">1905</dateCreated>
            <dateOther qualifier="approximate" point="end">1925</dateOther>
          </originInfo>
        </mods>
      XML
    end

    xit 'splits dateCreated into separate originInfo;  dateOther becomes dateCreated' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="something" eventType="production">
            <dateCreated keyDate="yes" encoding="w3cdtf">1905</dateCreated>
          </originInfo>
          <originInfo eventType="production">
            <dateCreated qualifier="approximate" point="end">1925</dateCreated>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when dateOther with type manufacture and publisher element' do
    # based on d527ky9095, zw971gd0220
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="manufacturer">
            <publisher>J. Jennings Lith. 326 Sansome St.,</publisher>
            <dateOther type="manufacture">1873.</dateOther>
          </originInfo>
        </mods>
      XML
    end

    xit 'moves dateCreated into its own originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="manufacturer">
            <dateOther type="manufacture">1873</dateOther>
          </originInfo>
          <originInfo eventType="publication">
            <publisher>J. Jennings Lith. 326 Sansome St.,</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when copyrightDate and issuance in single originInfo' do
    # based on kc487sz0076
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="copyright">
            <copyrightDate encoding="marc">2005</copyrightDate>
            <issuance>monographic</issuance>
          </originInfo>
        </mods>
      XML
    end

    xit 'splits copyrightDate from issuance' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="copyright">
            <copyrightDate encoding="marc">2005</copyrightDate>
          </originInfo>
          <originInfo eventType="publication">
            <issuance>monographic</issuance>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when eventType manufacture with publisher element' do
    # based on jz402xk5530
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="manufacturer" eventType="manufacture">
            <publisher>Lithographed in the Reproduction Branch, SSU</publisher>
            <dateOther/>
          </originInfo>
        </mods>
      XML
    end

    # TODO: ask Arcadia if there are more constraints on this one
    xit 'eventType becomes publication' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="manufacturer" eventType="publication">
            <publisher>Lithographed in the Reproduction Branch, SSU</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when eventType distribution with publisher element' do
    # based on rm699mr9758, xy550sj6776
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="distribution">
            <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
          </originInfo>
        </mods>
      XML
    end

    xit 'eventType becomes publication' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <publisher>For sale by the Superintendent of Documents, U.S. Government Publishing Office</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when eventType capture with dateCaptured and publisher elements' do
    # based on rn990mm7360
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="capture">
            <publisher>California. State Department of Education. Office of Curriculum Services</publisher>
            <dateCaptured keyDate="yes" encoding="iso8601" point="start">2007-12-10</dateCaptured>
            <dateCaptured encoding="iso8601" point="end">2011-01-24</dateCaptured>
          </originInfo>
        </mods>
      XML
    end

    xit 'splits originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="capture">
            <dateCaptured keyDate="yes" encoding="iso8601" point="start">2007-12-10</dateCaptured>
            <dateCaptured encoding="iso8601" point="end">2011-01-24</dateCaptured>
          </originInfo>
          <originInfo eventType="publication">
            <publisher>California. State Department of Education. Office of Curriculum Services</publisher>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when eventType copyright with copyrightDate and place' do
    # based on vw478nk8207
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of creation" eventType="copyright">
            <place>
              <placeTerm type="text">San Francisco (Calif.)</placeTerm>
            </place>
            <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
            <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
          </originInfo>
        </mods>
      XML
    end

    xit 'splits originInfo' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of creation" eventType="copyright">
            <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
            <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
          </originInfo>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">San Francisco (Calif.)</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when eventType production with copyrightDate and place' do
    # based on vw478nk8207
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of creation" eventType="production">
            <place>
              <placeTerm type="text">San Francisco (Calif.)</placeTerm>
            </place>
            <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
            <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
          </originInfo>
        </mods>
      XML
    end

    xit 'splits originInfo and eventType production becomes copyright' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="Place of creation" eventType="copyright">
            <copyrightDate keyDate="yes" encoding="w3cdtf" qualifier="approximate" point="start">1970</copyrightDate>
            <copyrightDate encoding="w3cdtf" qualifier="approximate" point="end">1974</copyrightDate>
          </originInfo>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">San Francisco (Calif.)</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when  altRepGroup subelements are missing from one of the elements' do
    # based on xj114vt0439
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo altRepGroup="1" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Shanghai</placeTerm>
            </place>
            <publisher>Shanghai shu dian chu ban</publisher>
            <publisher>Xin hua shu dian Shanghai fa xing suo fa xing</publisher>
            <dateIssued>1992</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">上海:上海书店出版：</placeTerm>
            </place>
            <publisher>新华书店上海发行所发行,</publisher>
            <dateIssued>1992</dateIssued>
            <edition>第1版.</edition>
            <issuance>monographic</issuance>
          </originInfo>
        </mods>
      XML
    end

    xit 'adds second publisher to second originInfo in altRepGroup so all elements in altRepGroup are matched' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo altRepGroup="1" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">Shanghai</placeTerm>
            </place>
            <publisher>Shanghai shu dian chu ban</publisher>
            <publisher>Xin hua shu dian Shanghai fa xing suo fa xing</publisher>
            <dateIssued>1992</dateIssued>
            <edition>Di 1 ban.</edition>
            <issuance>monographic</issuance>
          </originInfo>
          <originInfo altRepGroup="1" eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">cc</placeTerm>
            </place>
            <place>
              <placeTerm type="text">上海:上海书店出版：</placeTerm>
            </place>
            <publisher>新华书店上海发行所发行,</publisher>
            <publisher>Xin hua shu dian Shanghai fa xing suo fa xing</publisher>
            <dateIssued>1992</dateIssued>
            <edition>第1版.</edition>
            <issuance>monographic</issuance>
          </originInfo>
        </mods>
      XML
    end
  end
end
