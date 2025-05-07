# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MoveDigitalSerials do
  subject(:migrator) { described_class.new(repository_object) }

  let(:repository_object_version) { build(:repository_object_version, description:, identification:) }
  let(:repository_object) do
    create(:repository_object, :with_repository_object_version, repository_object_version:,
                                                                external_identifier: 'druid:bc177tq6734')
  end
  let(:identification) do
    { catalogLinks: [{ catalog: 'folio', catalogRecordId: 'a1234', refresh: false }],
      sourceId: 'sul:sourceId' }
  end
  let(:description) do
    {
      title: [
        {
          structuredValue: [
            { type: 'main title', value: 'Main Title' },
            { type: 'part number', value: 'Volume 1' },
            { type: 'part name', value: 'Spring' }
          ]
        }
      ],
      note: [
        { type: 'date/sequential designation', value: '2023.01' },
        { type: 'abstract', value: 'An abstract' }
      ]
    }
  end

  describe '#migrate?' do
    subject { migrator.migrate? }

    it { is_expected.to be true }
  end

  describe 'migrate' do
    it 'populates the catalogLink partLabel and sortKey and deletes from description' do
      migrator.migrate
      expect(repository_object.head_version.identification).to eq({ 'catalogLinks' => [{ 'catalog' => 'folio',
                                                                                         'catalogRecordId' => 'a1234',
                                                                                         'refresh' => true,
                                                                                         'partLabel' => 'Volume 1, Spring',
                                                                                         'sortKey' => '2023.01' }],
                                                                    'sourceId' => 'sul:sourceId' })
      expect(repository_object.head_version.description).to eq({ 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                                                                       'value' => 'Main Title' }] }],
                                                                 'note' => [{
                                                                   'type' => 'abstract', 'value' => 'An abstract'
                                                                 }] })
    end

    context 'when a parallelValue is present' do
      let(:description) do
        {
          title: [
            { parallelValue: [
              {
                structuredValue: [
                  { type: 'main title', value: 'Main Title' },
                  { type: 'part number', value: 'Volume 1' },
                  { type: 'part name', value: 'Summer' }
                ]
              }
            ] }
          ]
        }
      end

      it 'populates the catalogLink partLabel and sortKey and deletes from description' do
        migrator.migrate
        expect(repository_object.head_version.identification).to eq({ 'catalogLinks' => [{ 'catalog' => 'folio',
                                                                                           'catalogRecordId' => 'a1234',
                                                                                           'refresh' => true,
                                                                                           'partLabel' => 'Volume 1, Summer' }],
                                                                      'sourceId' => 'sul:sourceId' })
        expect(repository_object.head_version.description).to eq({ 'title' => [{ 'parallelValue' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                                                                                               'value' => 'Main Title' }] }] }] })
      end
    end

    context 'when no parts are present' do
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                { type: 'main title', value: 'Main Title' }
              ]
            }
          ]
        }
      end

      it 'does not change the catalogLink or title' do
        migrator.migrate
        expect(repository_object.head_version.identification).to eq({ 'catalogLinks' => [{ 'catalog' => 'folio',
                                                                                           'catalogRecordId' => 'a1234',
                                                                                           'refresh' => false }],
                                                                      'sourceId' => 'sul:sourceId' })
        expect(repository_object.head_version.description).to eq({ 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                                                                         'value' => 'Main Title' }] }] })
      end
    end

    context 'when no folio catalogLink is present' do
      let(:identification) do
        {  catalogLinks: [{ catalog: 'symphony', catalogRecordId: '1234', refresh: false }],
           sourceId: 'sul:sourceId' }
      end

      it 'does not populate the catalogLink partLabel and sortKey' do
        migrator.migrate

        expect(repository_object.head_version.identification).to eq({ 'catalogLinks' => [{ 'catalog' => 'symphony',
                                                                                           'catalogRecordId' => '1234',
                                                                                           'refresh' => false }],
                                                                      'sourceId' => 'sul:sourceId' })
      end

      it 'does not delete the title parts' do
        migrator.migrate

        expect(repository_object.head_version.description).to eq({ 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                                                                         'value' => 'Main Title' },
                                                                                                       { 'type' => 'part number',
                                                                                                         'value' => 'Volume 1' },
                                                                                                       { 'type' => 'part name',
                                                                                                         'value' => 'Spring' }] }],
                                                                   'note' => [{ 'type' => 'date/sequential designation', 'value' => '2023.01' },
                                                                              { 'type' => 'abstract',
                                                                                'value' => 'An abstract' }] })
      end
    end

    context 'when no catalogLink is present' do
      let(:identification) do
        { sourceId: 'sul:sourceId' }
      end

      it 'does not populate the catalogLink partLabel and sortKey' do
        migrator.migrate

        expect(repository_object.head_version.identification).to eq({ 'sourceId' => 'sul:sourceId' })
      end
    end
  end

  describe '#publish?' do
    it 'returns false as migrated SDR objects should not be published' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    it 'returns false as migrated SDR objects should not be versioned' do
      expect(migrator.version?).to be false
    end
  end

  describe '#version_description' do
    it 'raises an error as version? is never true' do
      expect { migrator.version_description }.to raise_error(NotImplementedError)
    end
  end
end
