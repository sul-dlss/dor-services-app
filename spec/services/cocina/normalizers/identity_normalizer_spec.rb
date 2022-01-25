# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::Normalizers::IdentityNormalizer do
  let(:normalized_ng_xml) { described_class.normalize(identity_ng_xml: Nokogiri::XML(original_xml)) }

  context 'when #normalize_source_id_whitespace' do
    let(:original_xml) do
      <<~XML
        <identityMetadata>
           <sourceId source=" sul "> M0443_S2_D-K_B9_F33_011 </sourceId>
        </identityMetadata>
      XML
    end

    it 'removes spaces' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <identityMetadata>
             <sourceId source="sul">M0443_S2_D-K_B9_F33_011</sourceId>
             <objectCreator>DOR</objectCreator>
          </identityMetadata>
        XML
      )
    end
  end

  describe '#normalize_dissertation_id_to_source_id' do
    context 'when there is an existing sourceId' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
             <sourceId source="foo">bar</sourceId>
             <otherId name="dissertationid">0000000666</otherId>
          </identityMetadata>
        XML
      end

      it 'does nothing' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <sourceId source="foo">bar</sourceId>
              <otherId name="dissertationid">0000000666</otherId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when no sourceId and there is otherId[@name=disserationid]' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
             <otherId name="dissertationid">0000000666</otherId>
          </identityMetadata>
        XML
      end

      it 'creates the new sourceId node and removes the otherId node' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <sourceId source="dissertationid">0000000666</sourceId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when no sourceId and there are many otherId nodes' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectId>foo</objectId>
            <objectType>item</objectType>
            <objectLabel>bar</objectLabel>
            <objectCreator>DOR</objectCreator>
            <otherId name="dissertationid">0000000666</otherId>
            <otherId name="catkey">666</otherId>
            <otherId name="uuid">bb8e629e-6328-11e1-9378-022c4a816c60</otherId>
          </identityMetadata>
        XML
      end

      it 'creates the new sourceId node from dissertationid node and removes the correct otherId node' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectId>foo</objectId>
              <objectType>item</objectType>
              <objectLabel>bar</objectLabel>
              <objectCreator>DOR</objectCreator>
              <sourceId source="dissertationid">0000000666</sourceId>
              <otherId name="catkey">666</otherId>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_uuid' do
    context 'when there is an otherId with name uuid' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <otherId name="catkey">666</otherId>
            <otherId name="uuid">bb8e629e-6328-11e1-9378-022c4a816c60</otherId>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <otherId name="catkey">666</otherId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_admin_tags' do
    context 'when there is one administrative tag' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectId>foo</objectId>
            <tag>fa la la felafel</tag>
            <otherId name="catkey">666</otherId>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectId>foo</objectId>
              <otherId name="catkey">666</otherId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when there are multiple administrative tags' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectId>foo</objectId>
            <tag>ETD : Term 1106</tag>
            <tag>ETD : Dissertation</tag>
            <tag>Remediated By : 4.20.1</tag>
            <otherId name="catkey">666</otherId>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectId>foo</objectId>
              <otherId name="catkey">666</otherId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_adminPolicy' do
    context 'when adminPolicy is present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectId>foo</objectId>
            <adminPolicy>druid:wq307yk9043</adminPolicy>
            <otherId name="catkey">666</otherId>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectId>foo</objectId>
              <otherId name="catkey">666</otherId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_agreementId' do
    context 'when agreementId is present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectId>foo</objectId>
            <otherId name="catkey">666</otherId>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectId>foo</objectId>
              <otherId name="catkey">666</otherId>
              <objectCreator>DOR</objectCreator>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_set_object_type' do
    context 'when objectType set and collection are both present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectType>set</objectType>
            <objectLabel>foo</objectLabel>
            <objectType>collection</objectType>
          </identityMetadata>
        XML
      end

      it 'removes objectType set' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
              <objectType>collection</objectType>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when objectType set is present alone' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectType>set</objectType>
            <objectLabel>foo</objectLabel>
          </identityMetadata>
        XML
      end

      it 'does not remove objectType set' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectType>set</objectType>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_display_type' do
    context 'when displayType is present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <displayType>file</displayType>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_object_admin_class' do
    context 'when objectAdminClass is present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <objectAdminClass>EEMs</objectAdminClass>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_citation_elements' do
    context 'when citationTitle alone is present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <citationTitle>Proceedings</citationTitle>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when citationCreator alone is present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <citationCreator>Dalton, Michael</citationCreator>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when both citationTitle and citationCreator are present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <citationTitle>Proceedings</citationTitle>
            <citationCreator>Dalton, Michael</citationCreator>
          </identityMetadata>
        XML
      end

      it 'removes them' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end

    context 'when empty citationTitle and citationCreator are present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <citationTitle/>
            <citationCreator></citationCreator>
          </identityMetadata>
        XML
      end

      it 'removes them' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_empty_other_ids' do
    context 'when otherId[@name="label"] is present but empty' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <otherId name=\"label\"/>
          </identityMetadata>
        XML
      end

      it 'removes it' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end
  end

  describe '#normalize_out_call_sequence_ids' do
    context 'when otherId[@name="shelfseq"] and otherId[@name="callseq"] are present' do
      let(:original_xml) do
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
            <otherId name="shelfseq">DA 000670 .S49 S55 V.000045-000046 001899-001900</otherId>
            <otherId name="callseq">29</otherId>
          </identityMetadata>
        XML
      end

      it 'removes them' do
        expect(normalized_ng_xml).to be_equivalent_to(
          <<~XML
            <identityMetadata>
              <objectCreator>DOR</objectCreator>
              <objectLabel>foo</objectLabel>
            </identityMetadata>
          XML
        )
      end
    end
  end

  context 'when there are duplicate catkeys' do
    let(:original_xml) do
      <<~XML
        <identityMetadata>
          <otherId name="catkey">90125</otherId>
          <otherId name="catkey">90125</otherId>
        </identityMetadata>
      XML
    end

    it 'collapses them' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <identityMetadata>
            <otherId name="catkey">90125</otherId>
            <objectCreator>DOR</objectCreator>
          </identityMetadata>
        XML
      )
    end
  end

  context 'when there is no objectCreator' do
    let(:original_xml) do
      <<~XML
        <identityMetadata>
          <objectLabel>foo</objectLabel>
        </identityMetadata>
      XML
    end

    it 'adds it' do
      expect(normalized_ng_xml).to be_equivalent_to(
        <<~XML
          <identityMetadata>
            <objectCreator>DOR</objectCreator>
            <objectLabel>foo</objectLabel>
          </identityMetadata>
        XML
      )
    end
  end
end
