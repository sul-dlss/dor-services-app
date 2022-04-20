# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectVersion, type: :model do
  let(:druid) { 'druid:xz456jk0987' }

  describe '#current_version' do
    before do
      described_class.create(druid: druid, version: 1, tag: '1.0.0')
      described_class.create(druid: druid, version: 2, tag: '1.1.0')
    end

    it 'returns current version' do
      expect(described_class.current_version(druid).tag).to eq('1.1.0')
    end
  end

  describe '#increment_version' do
    it 'increments version' do
      first_version = described_class.increment_version(druid)
      expect(first_version.version).to eq(1)
      expect(first_version.tag).to eq('1.0.0')
      expect(first_version.description).to eq('Initial Version')

      # With description and significance
      second_version = described_class.increment_version(druid, significance: :minor, description: 'An update')
      expect(second_version.version).to eq(2)
      expect(second_version.tag).to eq('1.1.0')
      expect(second_version.description).to eq('An update')

      # Without description or significance
      third_version = described_class.increment_version(druid)
      expect(third_version.version).to eq(3)
      expect(third_version.tag).to be_nil
      expect(third_version.description).to be_nil

      # Minor is ignored since last tag is null.
      # This replicates the current logic from https://github.com/sul-dlss/dor-services/blob/main/lib/dor/datastreams/version_metadata_ds.rb#L100
      fourth_version = described_class.increment_version(druid, significance: :minor, description: 'An update')
      expect(fourth_version.version).to eq(4)
      expect(fourth_version.tag).to be_nil
      expect(fourth_version.description).to eq('An update')
    end
  end

  describe '#sync_then_increment_version' do
    before do
      described_class.create(druid: druid, version: 1, tag: '1.0.0')
      described_class.create(druid: druid, version: 2, tag: '1.1.0')
    end

    context 'when in sync' do
      it 'increments version' do
        new_version = described_class.sync_then_increment_version(druid, 2, significance: :minor, description: 'An update')
        expect(new_version.version).to eq(3)
        expect(new_version.tag).to eq('1.2.0')
        expect(new_version.description).to eq('An update')
        expect(described_class.where(druid: druid).size).to eq(3)
      end
    end

    context 'when extra versions' do
      it 'deletes extra version' do
        new_version = described_class.sync_then_increment_version(druid, 1, significance: :major, description: 'An update')
        expect(new_version.version).to eq(2)
        expect(new_version.tag).to eq('2.0.0')
        expect(new_version.description).to eq('An update')
        expect(described_class.where(druid: druid).size).to eq(2)
      end
    end

    context 'when missing versions' do
      it 'raises' do
        expect { described_class.sync_then_increment_version(druid, 3) }.to raise_error(Dor::Exception)
      end
    end
  end

  describe '#update_current_version' do
    context 'when description and significance not provided' do
      before do
        described_class.create(druid: druid, version: 1, tag: '1.0.0')
        described_class.create(druid: druid, version: 2, tag: '1.1.0')
      end

      it 'does nothing' do
        described_class.update_current_version(druid)
        object_version = described_class.find_by(druid: druid, version: 2)
        expect(object_version.tag).to eq('1.1.0')
        expect(object_version.description).to be_nil
      end
    end

    context 'when no current object version' do
      it 'does nothing' do
        described_class.update_current_version(druid, significance: :major)
        expect(described_class.exists?(druid: druid)).to be(false)
      end
    end

    context 'when current version is 1' do
      before do
        described_class.create(druid: druid, version: 1, tag: '1.0.0')
      end

      it 'does not update' do
        described_class.update_current_version(druid: druid, significance: :minor)
        expect(described_class.current_version(druid).version).to eq(1)
      end
    end

    context 'when a description is provided' do
      before do
        described_class.create(druid: druid, version: 1, tag: '1.0.0')
        described_class.create(druid: druid, version: 2, tag: '1.1.0')
      end

      it 'updates description' do
        described_class.update_current_version(druid, description: 'an update')
        expect(described_class.find_by(druid: druid, version: 2).description).to eq('an update')
      end
    end

    context 'when current version has a tag' do
      before do
        described_class.create(druid: druid, version: 1, tag: '1.0.0')
        described_class.create(druid: druid, version: 2, tag: '1.1.0')
      end

      it 'updates tag ignoring current tag' do
        described_class.update_current_version(druid, significance: :major)
        expect(described_class.find_by(druid: druid, version: 2).tag).to eq('2.0.0')
      end
    end

    context 'when current version does not have a tag' do
      before do
        described_class.create(druid: druid, version: 1, tag: '1.0.0')
        described_class.create(druid: druid, version: 2)
      end

      it 'updates tag' do
        described_class.update_current_version(druid, significance: :minor)
        expect(described_class.find_by(druid: druid, version: 2).tag).to eq('1.1.0')
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
            <version versionId="2"/>
          </versionMetadata>
      XML
    end

    before do
      described_class.create(druid: druid, version: 1, tag: '1.0.0', description: 'Initial version')
      described_class.create(druid: druid, version: 2)
    end

    it 'returns xml' do
      expect(described_class.version_xml(druid)).to be_equivalent_to(expected_xml)
    end
  end
end
