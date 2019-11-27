# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataService do
  let(:mods) { File.read(File.join(fixture_dir, 'mods_record.xml')) }

  describe '#fetch' do
    let(:resource) { instance_double(MarcxmlResource, mods: mods) }

    before do
      allow(MarcxmlResource).to receive(:find_by).and_return(resource)
    end

    it 'raises an exception if an unknown metadata type is requested' do
      expect { described_class.fetch('foo:bar') }.to raise_exception(MetadataError)
    end

    it 'fetches a record based on barcode' do
      expect(described_class.fetch('barcode:12345')).to be_equivalent_to(mods)
      expect(MarcxmlResource).to have_received(:find_by).with(barcode: '12345')
    end

    it 'fetches a record based on catkey' do
      expect(described_class.fetch('catkey:12345')).to be_equivalent_to(mods)
      expect(MarcxmlResource).to have_received(:find_by).with(catkey: '12345')
    end
  end

  describe '#label_for' do
    subject { described_class.label_for('barcode:12345') }

    before do
      allow(described_class).to receive(:fetch).and_return(mods)
    end

    it { is_expected.to eq 'The isomorphism and thermal properties of the feldspars' }
  end
end
