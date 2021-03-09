# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ModsNormalizers::OriginInfoNormalizer do
  let(:normalized_ng_xml) { Cocina::ModsNormalizer.normalize(mods_ng_xml: mods_ng_xml, druid: nil, label: nil).to_xml }

  context 'when empty child elements' do
    describe 'empty originInfo date elements' do
      context 'when dateCreated' do
        # based on jw174hd9042, vy673zb2925
        let(:mods_ng_xml) do
          Nokogiri::XML <<~XML
            <mods #{MODS_ATTRIBUTES}>
              <originInfo>
                <dateCreated></dateCreated>
                <dateCreated/>
                <dateCreated />
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

        it 'removes the element' do
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

        it 'removes the element' do
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

    describe 'empty publisher element' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <publisher></publisher>
              <publisher/>
              <publisher />
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

    describe 'empty place element' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <place></place>
              <place/>
              <place />
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

    describe 'place/placeTerm has valueURI attribute' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <place>
                <placeTerm valueURI="http://id.loc.gov/authorities/names/n79118971"></placeTerm>
              </place>
            </originInfo>
          </mods>
        XML
      end

      it 'keeps the placeTerm element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <place>
                <placeTerm valueURI="http://id.loc.gov/authorities/names/n79118971"></placeTerm>
              </place>
            </originInfo>
          </mods>
        XML
      end
    end

    describe 'has xlink:href attribute' do
      # not likely but being thorough
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <place>
                <placeTerm xlink:href="http://name.org/name"></placeTerm>
              </place>
            </originInfo>
          </mods>
        XML
      end

      it 'keeps the placeTerm element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <place>
                <placeTerm xlink:href="http://name.org/name"></placeTerm>
              </place>
            </originInfo>
          </mods>
        XML
      end
    end

    # also does issuance, edition, frequency (it's using * to get all child elements)

    context 'when dateIssued with attributes but no content' do
      # based on vj932ns8042
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateIssued encoding="w3cdtf" keyDate="yes"/>
              <publisher>United Nations Conference on Trade</publisher>
              <issuance>monographic</issuance>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the dateIssued element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <publisher>United Nations Conference on Trade</publisher>
              <issuance>monographic</issuance>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'when placeTerm has attribute and dateIssued has content and an empty attribute' do
      # based on gh074sd3455
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <place>
                <placeTerm type="text"/>
              </place>
              <publisher/>
              <dateIssued encoding="w3cdtf" keyDate="yes" qualifier="">1931</dateIssued>
            </originInfo>
          </mods>
        XML
      end

      it 'removes all but the dateIssued element, and removes empty attribute' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo>
              <dateIssued encoding="w3cdtf" keyDate="yes">1931</dateIssued>
            </originInfo>
          </mods>
        XML
      end
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

      it 'removes the originInfo element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
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

      it 'removes the originInfo element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end

    context 'when originInfo, placeTerm and dateOther have attributes but no content' do
      # based on qy796rh6653
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="production">
              <place>
                <placeTerm type="text"/>
              </place>
              <publisher/>
              <dateOther type="production"/>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the originInfo element' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing legacy mods event types' do
    context 'when legacy displayLabel and no eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo displayLabel="publisher">
              <publisher>foo</publisher>
            </originInfo>
          </mods>
        XML
      end

      it 'converts the displayLabel to the correct eventType' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication">
              <publisher>foo</publisher>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'when legacy displayLabel and matching eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication" displayLabel="publisher">
              <publisher>foo</publisher>
            </originInfo>
          </mods>
        XML
      end

      it 'removes the displayLabel' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication">
              <publisher>foo</publisher>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'when legacy displayLabel and non-matching eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="capture" displayLabel="publisher">
              <publisher>foo</publisher>
            </originInfo>
          </mods>
        XML
      end

      it 'leaves the displayLabel as is' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="capture" displayLabel="publisher">
              <publisher>foo</publisher>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'when non-legacy displayLabel and eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication" displayLabel="foo">
              <publisher>bar</publisher>
            </originInfo>
          </mods>
        XML
      end

      it 'does not change displayLabel or eventType' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="publication" displayLabel="foo">
              <publisher>bar</publisher>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'when legacy eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="producer">
              <publisher>bar</publisher>
            </originInfo>
          </mods>
        XML
      end

      it 'normalizes eventType' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="production">
              <publisher>bar</publisher>
            </originInfo>
          </mods>
        XML
      end
    end

    context 'when non-legacy eventType' do
      let(:mods_ng_xml) do
        Nokogiri::XML <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="foo">
              <publisher>bar</publisher>
            </originInfo>
          </mods>
        XML
      end

      it 'does not change eventType' do
        expect(normalized_ng_xml).to be_equivalent_to <<~XML
          <mods #{MODS_ATTRIBUTES}>
            <originInfo eventType="foo">
              <publisher>bar</publisher>
            </originInfo>
          </mods>
        XML
      end
    end
  end

  context 'when normalizing placeTerm text values' do
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
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">[Stanford, California] :</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when removing trailing period from date values' do
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

  context 'when normalizing authority marcountry to marccountry' do
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <place>
              <placeTerm type="code" authority="marcountry" authorityURI="http://id.loc.gov/vocabulary/countries/"
                valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end

    it 'removes the empty child' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <place>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/"
                valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when placeTerm is empty and dateOther has only content and legacy mods displaLabel' do
    # based on wm519yn6490
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo displayLabel="producer">
            <place>
              <placeTerm/>
            </place>
            <publisher/>
            <dateOther type="production">June 7, 1977.</dateOther>
          </originInfo>
        </mods>
      XML
    end

    it 'removes all but the dateOther element, removes trailing period and corrects legacy displayLabel to eventType' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="production">
            <dateOther type="production">June 7, 1977</dateOther>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when placeTerm has an ampersand' do
    # based on zn500ww2119
    # <?xml version="1.0" encoding="UTF-8"?>
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">Leipzig :bVelhagen &amp; Klasing</placeTerm>
            </place>
            <publisher/>
            <dateIssued>[between 1940 and 1950?]</dateIssued>
          </originInfo>
        </mods>
      XML
    end

    it 'copes with xml decoding and encoding' do
      # NOTE: below requires processing instruction inclusion to pass
      #  And it is showing as error in production roundtrip validations without it
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <mods #{MODS_ATTRIBUTES}>
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text">Leipzig :bVelhagen &amp; Klasing</placeTerm>
            </place>
            <dateIssued>[between 1940 and 1950?]</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when date value has square brackets and question mark' do
    # based on ks031qj5177, zn500ww2119
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <dateOther type="production">[1797?]</dateOther>
          </originInfo>
        </mods>
      XML
    end

    it 'copes with chars' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <dateOther type="production">[1797?]</dateOther>
          </originInfo>
        </mods>
      XML
    end
  end

  context 'when placeTerm has square brackets and question mark' do
    # based on gy852bt1470
    let(:mods_ng_xml) do
      Nokogiri::XML <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <place>
               <placeTerm type="text">[Berlin?]</placeTerm>
             </place>
             <dateIssued>1940-[44]</dateIssued>
          </originInfo>
        </mods>
      XML
    end

    it 'copes with chars' do
      expect(normalized_ng_xml).to be_equivalent_to <<~XML
        <mods #{MODS_ATTRIBUTES}>
          <originInfo>
            <place>
               <placeTerm type="text">[Berlin?]</placeTerm>
             </place>
             <dateIssued>1940-[44]</dateIssued>
          </originInfo>
        </mods>
      XML
    end
  end
end
