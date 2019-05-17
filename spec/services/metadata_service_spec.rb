# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataService do
  it 'raises an exception if an unknown metadata type is requested' do
    expect { described_class.fetch('foo:bar') }.to raise_exception(MetadataError)
  end

  describe 'Symphony handler' do
    let(:resource) { instance_double(MarcxmlResource, mods: mods) }
    let(:mods) { File.read(File.join(fixture_dir, 'mods_record.xml')) }

    before do
      allow(MarcxmlResource).to receive(:find_by).and_return(resource)
    end

    it 'fetches a record based on barcode' do
      expect(described_class.fetch('barcode:12345')).to be_equivalent_to(mods)
      expect(MarcxmlResource).to have_received(:find_by).with(barcode: '12345')
    end

    it 'fetches a record based on catkey' do
      expect(described_class.fetch('catkey:12345')).to be_equivalent_to(mods)
      expect(MarcxmlResource).to have_received(:find_by).with(catkey: '12345')
    end

    it 'returns the MODS title as the label' do
      expect(described_class.label_for('barcode:12345')).to eq('The isomorphism and thermal properties of the feldspars')
      expect(MarcxmlResource).to have_received(:find_by).with(barcode: '12345')
    end
  end
end
