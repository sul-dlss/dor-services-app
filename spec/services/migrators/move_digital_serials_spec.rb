# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MoveDigitalSerials do
  subject(:migrator) { described_class.new(repository_object) }

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

    let(:repository_object) do
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734')
    end

    it { is_expected.to be true }
  end

  describe 'migrate' do
    context 'when a catalogLink is present' do
      let(:repository_object) { repository_object_version.repository_object }
      let(:repository_object_version) do
        create(:repository_object_version, :with_repository_object, description:, identification:,
                                                                    external_identifier: 'druid:bc177tq6734')
      end

      it 'populates the catalogLink partLabel and sortKey and deletes from description' do
        migrator.migrate

        expect(repository_object.head_version.identification).to eq(
          { 'catalogLinks' => [{ 'catalog' => 'folio',
                                 'catalogRecordId' => 'a1234',
                                 'refresh' => true,
                                 'partLabel' => 'Volume 1, Spring',
                                 'sortKey' => '2023.01' }],
            'sourceId' => 'sul:sourceId' }
        )
        expect(repository_object.head_version.description).to eq(
          { 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                  'value' => 'Main Title' }] }],
            'note' => [{
              'type' => 'abstract', 'value' => 'An abstract'
            }] }
        )
      end
    end

    context 'when a parallelValue is present' do
      let(:repository_object) { repository_object_version.repository_object }
      let(:repository_object_version) do
        create(:repository_object_version, :with_repository_object, description:, identification:,
                                                                    external_identifier: 'druid:bc177tq6734')
      end
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
        expect(repository_object.head_version.identification).to eq(
          { 'catalogLinks' => [{ 'catalog' => 'folio',
                                 'catalogRecordId' => 'a1234',
                                 'refresh' => true,
                                 'partLabel' => 'Volume 1, Summer' }],
            'sourceId' => 'sul:sourceId' }
        )
        expect(repository_object.head_version.description).to eq(
          { 'title' => [{ 'parallelValue' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                                        'value' => 'Main Title' }] }] }] }
        )
      end
    end

    context 'when there are three title parts' do
      let(:repository_object) { repository_object_version.repository_object }
      let(:repository_object_version) do
        create(:repository_object_version, :with_repository_object, description:, identification:,
                                                                    external_identifier: 'druid:bc177tq6734')
      end
      let(:description) do
        {
          title: [
            {
              structuredValue: [
                { type: 'main title', value: 'Main Title' },
                { type: 'part number', value: 'Volume 1' },
                { type: 'part name', value: 'Spring' },
                { type: 'part number', value: '2023 May' }
              ]
            }
          ]
        }
      end

      it 'populates the catalogLink partLabel with correct punctuation' do
        migrator.migrate
        expect(repository_object.head_version.identification).to eq(
          { 'catalogLinks' => [{ 'catalog' => 'folio',
                                 'catalogRecordId' => 'a1234',
                                 'refresh' => true,
                                 'partLabel' => 'Volume 1, Spring. 2023 May' }],
            'sourceId' => 'sul:sourceId' }
        )
        expect(repository_object.head_version.description).to eq(
          { 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                  'value' => 'Main Title' }] }] }
        )
      end
    end

    context 'when no parts are present' do
      let(:repository_object_version) do
        create(:repository_object_version, :with_repository_object, description:, identification:,
                                                                    external_identifier: 'druid:bc177tq6734')
      end
      let(:repository_object) { repository_object_version.repository_object }
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
        expect(repository_object.head_version.description).to eq(
          { 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                  'value' => 'Main Title' }] }] }
        )
      end
    end

    context 'when no folio catalogLink is present' do
      let(:repository_object_version) do
        create(:repository_object_version, :with_repository_object, description:, identification:,
                                                                    external_identifier: 'druid:bc177tq6734')
      end
      let(:repository_object) { repository_object_version.repository_object }
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

        expect(repository_object.head_version.description).to eq(
          { 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                  'value' => 'Main Title' },
                                                { 'type' => 'part number',
                                                  'value' => 'Volume 1' },
                                                { 'type' => 'part name',
                                                  'value' => 'Spring' }] }],
            'note' => [{ 'type' => 'date/sequential designation', 'value' => '2023.01' },
                       { 'type' => 'abstract',
                         'value' => 'An abstract' }] }
        )
      end
    end

    context 'when no catalogLink is present' do
      let(:repository_object_version) do
        create(:repository_object_version, :with_repository_object, description:, identification:,
                                                                    external_identifier: 'druid:bc177tq6734')
      end
      let(:repository_object) { repository_object_version.repository_object }
      let(:identification) do
        { sourceId: 'sul:sourceId' }
      end

      it 'does not populate the catalogLink partLabel and sortKey' do
        migrator.migrate

        expect(repository_object.head_version.identification).to eq({ 'sourceId' => 'sul:sourceId' })
      end
    end

    context 'when head version is not last closed version' do
      let(:repository_object) { create(:repository_object, :closed) }
      let!(:repository_object_version2) do
        create(:repository_object_version, repository_object:, closed_at: Time.zone.now, description: description1,
                                           identification:, version: 2)
      end
      let!(:repository_object_version3) do
        create(:repository_object_version, repository_object:, description:, identification:, version: 3)
      end
      let(:description1) do
        {
          title: [
            {
              structuredValue: [
                { type: 'main title', value: 'Main Title' },
                { type: 'part number', value: 'Volume 1' },
                { type: 'part name', value: 'Winter' }
              ]
            }
          ],
          note: [
            { type: 'date/sequential designation', value: '2020.01' },
            { type: 'abstract', value: 'An abstract' }
          ]
        }
      end

      before do
        repository_object.update(head_version: repository_object_version3, opened_version: repository_object_version3,
                                 last_closed_version: repository_object_version2)
      end

      it 'migrates both the last closed version and head version' do
        migrator.migrate
        expect(repository_object.head_version.identification).to eq(
          { 'catalogLinks' => [{ 'catalog' => 'folio',
                                 'catalogRecordId' => 'a1234',
                                 'refresh' => true,
                                 'partLabel' => 'Volume 1, Spring',
                                 'sortKey' => '2023.01' }],
            'sourceId' => 'sul:sourceId' }
        )
        expect(repository_object.head_version.description).to eq(
          { 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                  'value' => 'Main Title' }] }],
            'note' => [{
              'type' => 'abstract', 'value' => 'An abstract'
            }] }
        )
        expect(repository_object.last_closed_version.identification).to eq(
          { 'catalogLinks' => [{ 'catalog' => 'folio',
                                 'catalogRecordId' => 'a1234',
                                 'refresh' => true,
                                 'partLabel' => 'Volume 1, Winter',
                                 'sortKey' => '2020.01' }],
            'sourceId' => 'sul:sourceId' }
        )
        expect(repository_object.last_closed_version.description).to eq(
          { 'title' => [{ 'structuredValue' => [{ 'type' => 'main title',
                                                  'value' => 'Main Title' }] }],
            'note' => [{
              'type' => 'abstract', 'value' => 'An abstract'
            }] }
        )
      end
    end
  end

  describe '#publish?' do
    let(:repository_object) do
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734')
    end

    it 'returns false as migrated SDR objects should not be published' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    let(:repository_object) do
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734')
    end

    it 'returns false as migrated SDR objects should not be versioned' do
      expect(migrator.version?).to be false
    end
  end

  describe '#version_description' do
    let(:repository_object) do
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734')
    end

    it 'raises an error as version? is never true' do
      expect { migrator.version_description }.to raise_error(NotImplementedError)
    end
  end
end
