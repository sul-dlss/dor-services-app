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
            { type: 'part name', value: 'Spring' },
            { type: 'part number', value: '2023 May' }
          ]
        }
      ],
      note: [
        { type: 'date/sequential designation', value: '2023.01' },
        { type: 'abstract', value: 'An abstract' }
      ]
    }
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
                                 'partLabel' => 'Volume 1, Spring. 2023 May',
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
  end

  describe '#migrate?' do
    subject { migrator.migrate? }

    let(:repository_object) do
      create(:repository_object, :with_repository_object_version, external_identifier: 'druid:bc177tq6734')
    end

    it { is_expected.to be true }
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
