# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS note <--> cocina mappings' do
  describe 'Simple note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note>This is a note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a note.'
            }
          ]
        }
      end
    end
  end

  describe 'Note with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note type="preferred citation">This is the preferred citation.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is the preferred citation.',
              type: 'preferred citation'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note lang="eng" altRepGroup="1">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              parallelValue: [
                {
                  value: 'This is a note.',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  value: "C'est une note.",
                  valueLanguage: {
                    code: 'fre',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Link to external value only' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <note xlink:href="http://note.org/note" />
      XML
    end

    let(:cocina) do
      {
        note: [
          {
            valueAt: 'http://note.org.note'
          }
        ]
      }
    end
  end

  describe 'Note with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note displayLabel="Conservation note">This is a conservation note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a conservation note.',
              displayLabel: 'Conservation note'
            }
          ]
        }
      end
    end
  end

  ## Data error - do not warn
  describe 'Note with unmatched altRepGroup' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <note type="statement of responsibility" altRepGroup="00">by Dorothy L. Sayers</note>
      XML
    end

    let(:cocina) do
      {
        note: [
          {
            value: 'by Dorothy L. Sayers',
            type: 'statement of responsibility'
          }
        ]
      }
    end

    let(:roundtrip_mods) do
      <<~XML
        <note type="statement of responsibility">by Dorothy L. Sayers</note>
      XML
    end
  end
end
