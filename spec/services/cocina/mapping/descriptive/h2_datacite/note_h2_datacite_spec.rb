# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina --> DataCite mappings for note' do
  # NOTE: Because we haven't set a title in this Cocina::Models::Description, it will not validate against the openapi.
  let(:cocina_description) do
    Cocina::Models::Description.new(cocina.merge(purl: cocina.fetch(:purl, 'https://purl.stanford.edu/aa666bb1234')),
                                    false, false)
  end
  let(:descriptions_attributes) { Cocina::ToDatacite::Note.descriptions_attributes(cocina_description) }

  describe 'Abstract' do
    let(:cocina) do
      {
        note: [
          {
            type: 'abstract',
            value: 'My paper is about dolphins.'
          }
        ]
      }
    end

    it 'populates descriptions_attributes correctly' do
      # let(:datacite_xml) do
      #   <<~XML
      #     <descriptions>
      #       <description descriptionType="Abstract">My paper is about dolphins.</description>
      #     </descriptions>
      #   XML
      # end
      expect(descriptions_attributes).to eq [
        {
          description: 'My paper is about dolphins.',
          descriptionType: 'Abstract'
        }
      ]
    end
  end

  ### --------------- specs below added by developers ---------------

  context 'when cocina note array has empty hash' do
    let(:cocina) do
      {
        note: [
          {
          }
        ]
      }
    end

    it 'descriptions_attributes is nil' do
      expect(descriptions_attributes).to be_nil
    end
  end

  context 'when cocina note is empty array' do
    let(:cocina) do
      {
        note: []
      }
    end

    it 'descriptions_attributes is nil' do
      expect(descriptions_attributes).to be_nil
    end
  end

  context 'when cocina has no note' do
    let(:cocina) do
      {
      }
    end

    it 'descriptions_attributes is nil' do
      expect(descriptions_attributes).to be_nil
    end
  end
end
