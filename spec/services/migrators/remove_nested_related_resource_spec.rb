# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RemoveNestedRelatedResource do
  subject(:migrator) do
    described_class.new(model_hash: model_hash, valid: true, opened_version: opened_version,
                        last_closed_version: last_closed_version, head_version: false)
  end

  let(:opened_version) { false }
  let(:last_closed_version) { false }

  describe 'migrate' do
    subject(:migrated_model_hash) { migrator.migrate }

    let(:model_hash) do
      # Only providing description instead of complete model hash.
      { 'description' => description.deep_dup }
    end

    let(:description) do
      { 'title' => 'Test Title',
        'relatedResource' => related_resource,
        'purl' => 'https://purl.stanford.edu' }
    end

    let(:related_resource) do
      [
        {
          'type' => 'has original version',
          'title' => [{ 'value' => 'The complete works of Henry George.' }],
          'form' => [{ 'value' => 'print', 'type' => 'form' }],
          'relatedResource' => []
        }
      ]
    end

    it 'removes nested relatedResource from description' do
      migrated_description = migrated_model_hash['description'].with_indifferent_access
      expect(migrated_description)
        .to match(
          {
            title: 'Test Title',
            relatedResource: [
              {
                type: 'has original version',
                title: [{ value: 'The complete works of Henry George.' }],
                form: [{ value: 'print', type: 'form' }]
              }
            ],
            purl: 'https://purl.stanford.edu'
          }
        )
    end

    context 'when a nested relatedResource itself has a nested relatedResource' do
      let(:related_resource) do
        [
          {
            'type' => 'has original version',
            'title' => [{ 'value' => 'The complete works of Henry George.' }],
            'relatedResource' => [
              {
                'type' => 'has original version',
                'relatedResource' => []
              }
            ]
          }
        ]
      end

      context 'when an old version (not opened or last closed)' do
        it 'leaves the nested relatedResource' do
          migrated_description = migrated_model_hash['description'].with_indifferent_access
          expect(migrated_description[:relatedResource].first[:relatedResource]).to eq(
            [{ 'type' => 'has original version', 'relatedResource' => [] }.with_indifferent_access]
          )
        end
      end

      context 'when the opened version' do
        let(:opened_version) { true }

        it 'raises' do
          expect { migrated_model_hash }.to raise_error('Nested relatedResource found')
        end
      end

      context 'when the last closed version' do
        let(:last_closed_version) { true }

        it 'raises' do
          expect { migrated_model_hash }.to raise_error('Nested relatedResource found')
        end
      end
    end
  end

  describe '#migration_strategy' do
    it 'returns commit since using base default' do
      expect(described_class.migration_strategy).to eq :commit
    end
  end
end
