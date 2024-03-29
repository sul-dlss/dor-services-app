# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectVersion do
  let(:druid) { 'druid:xz456jk0987' }

  describe '#current_version' do
    before do
      described_class.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
      described_class.create(druid:, version: 2, tag: '1.1.0', description: 'Version 1.1.0')
    end

    it 'returns current version' do
      expect(described_class.current_version(druid).tag).to eq('1.1.0')
    end
  end

  describe '#initial_version' do
    let(:version) { described_class.initial_version(druid:) }

    it 'returns initial version' do
      expect(version.version).to eq(1)
      expect(version.tag).to eq('1.0.0')
      expect(version.description).to eq('Initial Version')
    end
  end

  describe '#increment_version' do
    it 'increments version' do
      # Initial significance and description are ignored.
      first_version = described_class.increment_version(druid:, significance: :minor, description: 'A description')
      expect(first_version.version).to eq(1)
      expect(first_version.tag).to eq('1.0.0')
      expect(first_version.description).to eq('Initial Version')

      # With description and significance
      second_version = described_class.increment_version(druid:, significance: :minor, description: 'An update')
      expect(second_version.version).to eq(2)
      expect(second_version.tag).to eq('1.1.0')
      expect(second_version.description).to eq('An update')
    end
  end

  describe '#sync_then_increment_version' do
    before do
      described_class.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
      described_class.create(druid:, version: 2, tag: '1.1.0', description: 'Version 1.1.0')
    end

    context 'when in sync' do
      it 'increments version' do
        new_version = described_class.sync_then_increment_version(druid:, known_version: 2, significance: :minor, description: 'An update')
        expect(new_version.version).to eq(3)
        expect(new_version.tag).to eq('1.2.0')
        expect(new_version.description).to eq('An update')
        expect(described_class.where(druid:).size).to eq(3)
      end
    end

    context 'when extra versions' do
      it 'deletes extra version' do
        new_version = described_class.sync_then_increment_version(druid:, known_version: 1, significance: :major, description: 'An update')
        expect(new_version.version).to eq(2)
        expect(new_version.tag).to eq('2.0.0')
        expect(new_version.description).to eq('An update')
        expect(described_class.where(druid:).size).to eq(2)
      end
    end

    context 'when missing versions' do
      it 'raises' do
        expect { described_class.sync_then_increment_version(druid:, known_version: 3, significance: :major, description: 'Version 3') }.to raise_error(VersionService::VersioningError)
      end
    end
  end

  describe '#update_current_version' do
    context 'when no current object version' do
      it 'does nothing' do
        described_class.update_current_version(druid:, significance: :major, description: 'Major version')
        expect(described_class.exists?(druid:)).to be(false)
      end
    end

    context 'when current version is 1' do
      before do
        described_class.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
      end

      it 'does not update' do
        described_class.update_current_version(druid:, significance: :minor, description: 'Minor version')
        expect(described_class.current_version(druid).version).to eq(1)
        expect(described_class.current_version(druid).description).to eq('Initial Version')
        expect(described_class.current_version(druid).tag).to eq('1.0.0')
      end
    end

    context 'when a description is provided' do
      before do
        described_class.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
        described_class.create(druid:, version: 2, tag: '1.1.0', description: 'Version 1.1.0')
      end

      it 'updates description' do
        described_class.update_current_version(druid:, description: 'an update')
        expect(described_class.find_by(druid:, version: 2).description).to eq('an update')
      end
    end

    context 'when current version has a tag' do
      before do
        described_class.create(druid:, version: 1, tag: '1.0.0', description: 'Initial Version')
        described_class.create(druid:, version: 2, tag: '1.1.0', description: 'Version 1.1.0')
      end

      it 'updates tag ignoring current tag' do
        described_class.update_current_version(druid:, significance: :major)
        expect(described_class.find_by(druid:, version: 2).tag).to eq('2.0.0')
      end
    end
  end

  describe '#version_xml' do
    let(:expected_xml) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
          <versionMetadata objectId="#{druid}">
            <version versionId="1" tag="1.0.0">
              <description>
                Initial version
              </description>
            </version>
            <version versionId="2" tag="2.0.0">
              <description>
                Version 2.0.0
              </description>
            </version>
          </versionMetadata>
      XML
    end

    before do
      described_class.create(druid:, version: 1, tag: '1.0.0', description: 'Initial version')
      described_class.create(druid:, version: 2, tag: '2.0.0', description: 'Version 2.0.0')
    end

    it 'returns xml' do
      expect(described_class.version_xml(druid)).to be_equivalent_to(expected_xml)
    end
  end
end
