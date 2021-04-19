# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::EmbargoMetadataGenerator do
  subject(:embargo_generator) do
    described_class.generate(embargo_metadata: embargo_ds, embargo: embargo)
  end

  let(:item) do
    Dor::Item.new
  end

  let(:embargo_ds) { item.datastreams['embargoMetadata'] }

  let(:embargo) do
    Cocina::Models::Embargo.new({
      releaseDate: release_date,
      access: access,
      download: download,
      useAndReproductionStatement: use_and_reproduction_statement
    }.compact)
  end

  let(:release_date) { DateTime.parse('2045-01-01') }

  let(:download) { nil }

  let(:use_and_reproduction_statement) { nil }

  before do
    embargo_generator
  end

  context 'when access is stanford' do
    let(:access) { 'stanford' }
    let(:download) { 'stanford' }

    it 'sets embargoMetadata to embargoed and release access to stanford' do
      expect(embargo_ds.ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <embargoMetadata>
              <status>embargoed</status>
              <releaseDate>2045-01-01T00:00:00Z</releaseDate>
              <twentyPctVisibilityStatus/>
              <twentyPctVisibilityReleaseDate/>
              <releaseAccess>
                <access type="discover">
                  <machine><world/></machine>
                </access>
                <access type="read">
                  <machine>
                    <group>stanford</group>
                    </machine>
                </access>
              </releaseAccess>
            </embargoMetadata>\n"
      XML
    end
  end

  context 'when access is world' do
    let(:access) { 'world' }
    let(:download) { 'world' }

    it 'sets embargoMetadata to embargoed and release access to world' do
      expect(embargo_ds.ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <embargoMetadata>
              <status>embargoed</status>
              <releaseDate>2045-01-01T00:00:00Z</releaseDate>
              <twentyPctVisibilityStatus/>
              <twentyPctVisibilityReleaseDate/>
              <releaseAccess>
                <access type="discover">
                  <machine><world/></machine>
                </access>
                <access type="read">
                  <machine>
                    <world />
                    </machine>
                </access>
              </releaseAccess>
            </embargoMetadata>\n"
      XML
    end

    context 'when use_and_reproduction_statement is provided' do
      let(:use_and_reproduction_statement) { 'in public domain' }

      it 'sets use_and_reproduction_statement' do
        expect(item.embargoMetadata.use_and_reproduction_statement).to eq ['in public domain']
      end
    end
  end

  context 'when access is dark' do
    let(:access) { 'dark' }

    it 'sets embargoMetadata to embargoed and release access to none' do
      expect(embargo_ds.ng_xml).to be_equivalent_to <<-XML
            <?xml version="1.0"?>
            <embargoMetadata>
              <status>embargoed</status>
              <releaseDate>2045-01-01T00:00:00Z</releaseDate>
              <twentyPctVisibilityStatus/>
              <twentyPctVisibilityReleaseDate/>
              <releaseAccess>
                <access type="discover">
                  <machine><none /></machine>
                </access>
                <access type="read">
                  <machine>
                    <none />
                    </machine>
                </access>
              </releaseAccess>
            </embargoMetadata>\n"
      XML
    end
  end
end
