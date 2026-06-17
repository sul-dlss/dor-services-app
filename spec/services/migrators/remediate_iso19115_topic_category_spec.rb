# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemediateIso19115TopicCategory do
  subject(:migrator) do
    described_class.new(model_hash: model_hash, valid: true, opened_version: false, last_closed_version: false,
                        head_version: false)
  end

  describe '.migration_strategy' do
    it 'returns cocina_update' do
      expect(described_class.migration_strategy).to eq :cocina_update
    end
  end

  describe '.version_description' do
    it 'returns the version description' do
      expect(described_class.version_description)
        .to eq 'Remediate ISO 19115 Topic Category subjects: move coded value from uri to code field.'
    end
  end

  describe '#migrate' do
    subject(:migrated_model_hash) { migrator.migrate }

    let(:geonames_subject) do
      {
        'value' => 'Alameda County (Calif.)',
        'type' => 'place',
        'uri' => 'http://sws.geonames.org/5322745/',
        'source' => { 'code' => 'geonames', 'uri' => 'http://www.geonames.org/ontology#' }
      }
    end

    let(:iso_subject_1) do # rubocop:disable Naming/VariableNumber
      {
        'value' => 'Planning and Cadastral',
        'type' => 'topic',
        'uri' => 'planningCadastre',
        'source' => {
          'code' => 'ISO19115TopicCategory',
          'uri' => 'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode'
        }
      }
    end

    let(:iso_subject_2) do # rubocop:disable Naming/VariableNumber
      {
        'value' => 'Transportation',
        'type' => 'topic',
        'uri' => 'transportation',
        'source' => {
          'code' => 'ISO19115TopicCategory',
          'uri' => 'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode'
        }
      }
    end

    context 'with ISO19115TopicCategory and non-ISO subjects' do
      let(:model_hash) do
        { 'description' => { 'subject' => [geonames_subject, iso_subject_1, iso_subject_2] } }
      end

      it 'moves uri to code for ISO19115TopicCategory subjects' do
        result = migrated_model_hash['description']['subject'].map(&:with_indifferent_access)
        expect(result[1]).to include(code: 'planningCadastre')
        expect(result[1]).not_to have_key(:uri)
        expect(result[2]).to include(code: 'transportation')
        expect(result[2]).not_to have_key(:uri)
      end

      it 'does not modify non-ISO subjects' do
        result = migrated_model_hash['description']['subject'].map(&:with_indifferent_access)
        expect(result[0]).to include(uri: 'http://sws.geonames.org/5322745/')
        expect(result[0]).not_to have_key(:code)
      end
    end

    context 'with no subjects' do
      let(:model_hash) { { 'description' => { 'title' => [{ 'value' => 'Test' }] } } }

      it 'returns model_hash unchanged' do
        expect(migrated_model_hash).to eq model_hash
      end
    end

    context 'with no ISO19115TopicCategory subjects' do
      let(:model_hash) { { 'description' => { 'subject' => [geonames_subject] } } }

      it 'returns model_hash unchanged' do
        expect(migrated_model_hash).to eq model_hash
      end
    end

    context 'with ISO19115TopicCategory subjects under relatedResource' do
      let(:model_hash) do
        {
          'description' => {
            'subject' => [geonames_subject],
            'relatedResource' => [
              {
                'subject' => [iso_subject_1]
              }
            ]
          }
        }
      end

      it 'moves uri to code for ISO subjects in relatedResource' do
        related_subject = migrated_model_hash.dig('description', 'relatedResource', 0, 'subject', 0)
        expect(related_subject['code']).to eq 'planningCadastre'
        expect(related_subject).not_to have_key('uri')
      end

      it 'does not modify top-level non-ISO subjects' do
        top_subject = migrated_model_hash.dig('description', 'subject', 0)
        expect(top_subject['uri']).to eq 'http://sws.geonames.org/5322745/'
        expect(top_subject).not_to have_key('code')
      end
    end

    context 'with an ISO19115TopicCategory subject that already has a code' do
      let(:iso_subject_with_code) do
        {
          'value' => 'Planning and Cadastral',
          'type' => 'topic',
          'uri' => 'planningCadastre',
          'code' => 'existingCode',
          'source' => {
            'code' => 'ISO19115TopicCategory',
            'uri' => 'http://www.isotc211.org/2005/resources/Codelist/gmxCodelists.xml#MD_TopicCategoryCode'
          }
        }
      end

      let(:model_hash) { { 'description' => { 'subject' => [iso_subject_with_code] } } }

      it 'does not overwrite the existing code' do
        result = migrated_model_hash['description']['subject'][0]
        expect(result['code']).to eq 'existingCode'
      end

      it 'leaves the uri in place' do
        result = migrated_model_hash['description']['subject'][0]
        expect(result['uri']).to eq 'planningCadastre'
      end
    end

    context 'with nil description' do
      let(:model_hash) { { 'description' => nil } }

      it 'returns model_hash unchanged' do
        expect(migrated_model_hash).to eq model_hash
      end
    end
  end
end
