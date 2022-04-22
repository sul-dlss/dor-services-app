# frozen_string_literal: true

require 'rails_helper'

RSpec.describe VersionMigrationService do
  let(:druid) { 'druid:fd953pg7906' }

  let(:item) do
    Dor::Item.new(pid: druid).tap do |item|
      item.versionMetadata.content = version_xml
    end
  end

  let(:version_xml) do
    <<~XML
      <versionMetadata objectId="#{druid}">
        <version tag="1.0.0" versionId="1">
          <description>Initial Version</description>
        </version>
        <version tag="1.0.1" versionId="2">
          <description>reaccession to preserve geoMetadata in SDR</description>
        </version>
        <version tag="1.1.0" versionId="3">
          <description>update object rights</description>
        </version>
        <version tag="1.2.0" versionId="4">
          <description>set rights</description>
        </version>
        <version tag="1.3.0" versionId="5">
          <description>Apply APO defaults</description>
        </version>
        <version tag="1.4.0" versionId="6">
          <description/>
        </version>
        <version tag="1.5.0" versionId="7">
          <description/>
        </version>
        <version tag="1.6.0" versionId="8">
          <description>update APO</description>
        </version>
        <version tag="1.7.0" versionId="9">
          <description/>
        </version>
        <version tag="1.8.0" versionId="10">
          <description/>
        </version>
        <version tag="1.9.0" versionId="11">
          <description/>
        </version>
        <version tag="1.10.0" versionId="12">
          <description/>
        </version>
      </versionMetadata>
    XML
  end

  context 'when migration not yet performed' do
    it 'populates versions' do
      described_class.migrate(item)
      expect(ObjectVersion.where(druid: druid).size).to eq(12)
      first_version = ObjectVersion.find_by(druid: druid, version: 1)
      expect(first_version.tag).to eq('1.0.0')
      expect(first_version.description).to eq('Initial Version')

      current_version = ObjectVersion.find_by(druid: druid, version: 12)
      expect(current_version.tag).to eq('1.10.0')
      expect(current_version.description).to eq('Version 1.10.0') # default
    end
  end

  context 'when migration already performed' do
    before do
      ObjectVersion.create(druid: druid, version: 1, tag: '1.0.0', description: 'Initial Version')
    end

    it 'does not populate versions' do
      expect(ObjectVersion.where(druid: druid).size).to eq(1)
      described_class.migrate(item)
      expect(ObjectVersion.where(druid: druid).size).to eq(1)
    end
  end

  context 'when version tag is missing' do
    let(:version_xml) do
      <<~XML
        <versionMetadata objectId="#{druid}">
          <version versionId="1">
            <description>Initial Version</description>
          </version>
        </versionMetadata>
      XML
    end

    it 'uses default of "<version>.0.0"' do
      described_class.migrate(item)
      first_version = ObjectVersion.find_by(druid: druid, version: 1)
      expect(first_version.tag).to eq('1.0.0')
      expect(first_version.description).to eq('Initial Version')
    end
  end

  context 'when version description is missing' do
    let(:version_xml) do
      <<~XML
        <versionMetadata objectId="#{druid}">
          <version tag="1.0.0" versionId="1">
          </version>
        </versionMetadata>
      XML
    end

    it 'uses default of "Version <tag>"' do
      described_class.migrate(item)
      first_version = ObjectVersion.find_by(druid: druid, version: 1)
      expect(first_version.tag).to eq('1.0.0')
      expect(first_version.description).to eq('Version 1.0.0')
    end
  end

  context 'when both tag and description are missing' do
    let(:version_xml) do
      <<~XML
        <versionMetadata objectId="#{druid}">
          <version versionId="1">
          </version>
        </versionMetadata>
      XML
    end

    it 'uses defaults of "<version>.0.0" for tag and "Version <tag>" for description' do
      described_class.migrate(item)
      first_version = ObjectVersion.find_by(druid: druid, version: 1)
      expect(first_version.tag).to eq('1.0.0')
      expect(first_version.description).to eq('Version 1.0.0')
    end
  end
end
