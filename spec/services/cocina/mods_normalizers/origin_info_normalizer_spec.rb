# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizers::OriginInfoNormalizer do
  let(:normalized_ng_xml) { Cocina::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: 'druid:pf694bk4862') }

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

    it 'removes dateOther type attribute if it matches eventType and dateOther is empty' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
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

  context 'when normalizing originInfo dates' do
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

    context 'when attributes attribute but no children' do
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

    context 'when no attributes but (empty) child' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <publisher/>
            </originInfo>
          </mods>
        XML
      end

      it 'does not remove it' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication">
              <publisher/>
            </originInfo>
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
end
