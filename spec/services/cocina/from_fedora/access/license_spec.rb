# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Access::License do
  subject(:license) { described_class.find(rights_metadata_ds) }

  let(:rights_metadata_ds) { Dor::RightsMetadataDS.from_xml(xml) }
  let(:xml) do
    <<~XML
      <?xml version="1.0"?>
      <rightsMetadata>
        #{use}
      </rightsMetadata>
    XML
  end

  describe 'with the license node' do
    let(:use) { '<use><license>https://spdx.org/licenses/Apache-2.0</license></use>' }

    it 'finds the license' do
      expect(license).to eq 'https://spdx.org/licenses/Apache-2.0'
    end
  end

  describe 'with the machine uri attribute' do
    let(:use) do
      <<~XML
        <use>
          <machine type="creativeCommons" uri="https://creativecommons.org/licenses/by-sa/4.0/">by-sa</machine>
        </use>
      XML
    end

    it 'finds the license' do
      expect(license).to eq 'https://creativecommons.org/licenses/by-sa/4.0/'
    end
  end

  describe 'with the an empty machine uri attribute' do
    let(:use) do
      <<~XML
        <use>
          <machine type="creativeCommons" uri=""></machine>
          <machine type="openDataCommons">odc-by</machine>
        </use>
      XML
    end

    it 'finds the license' do
      expect(license).to eq 'http://opendatacommons.org/licenses/by/1.0/'
    end
  end

  describe 'with just a code' do
    let(:use) do
      <<~XML
        <use>
          <human type="creativeCommons">CC-BY SA 4.0</human>
          <machine type="creativeCommons">by-sa</machine>
        </use>
      XML
    end

    it 'finds the license' do
      expect(license).to eq 'https://creativecommons.org/licenses/by-sa/3.0/'
    end
  end

  describe 'with none (to support some non-compliant legacy ETDs)' do
    let(:use) do
      <<~XML
        <use>
          <machine type="creativeCommons">none</machine>
          <machine type="openDataCommons"></machine>
        </use>
      XML
    end

    it 'finds the license' do
      expect(license).to eq 'http://cocina.sul.stanford.edu/licenses/none'
    end
  end
end
