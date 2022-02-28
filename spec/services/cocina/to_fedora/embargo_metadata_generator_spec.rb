# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::EmbargoMetadataGenerator do
  context 'when releasing embargo' do
    let(:embargo_metadata_ds) do
      Dor::EmbargoMetadataDS.new.tap do |ds|
        ds.content = embargo_metadata_xml
      end
    end

    let(:embargo_metadata_xml) do
      <<~XML
        <embargoMetadata>
          <status>embargoed</status>
          <releaseDate>2058-09-01T08:00:00Z</releaseDate>
          <releaseAccess>
            <access type="discover">
              <machine>
                <world/>
              </machine>
            </access>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
            <use>
              <human type="useAndReproduction">The materials are open for research use and may be used freely for non-commercial purposes with an attribution. For commercial permission requests, please contact the Stanford University Archives (universityarchives@stanford.edu).</human>
            </use>
          </releaseAccess>
        </embargoMetadata>
      XML
    end

    it 'changes status' do
      described_class.generate(embargo_metadata: embargo_metadata_ds, embargo: nil)
      expect(embargo_metadata_ds.status).to eq('released')
    end
  end

  context 'when no existing embargo' do
    let(:embargo_metadata_ds) do
      Dor::EmbargoMetadataDS.new
    end

    it 'does not change status' do
      described_class.generate(embargo_metadata: embargo_metadata_ds, embargo: nil)
      expect(embargo_metadata_ds.status).to eq('')
    end
  end
end
