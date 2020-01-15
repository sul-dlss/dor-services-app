# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MetadataService do
  let(:mods) { File.read(File.join(fixture_dir, 'mods_record.xml')) }

  describe '#resolvable' do
    it 'returns only resolvable identifiers' do
      expect(described_class.resolvable(['bogus:1234', 'catkey:5678'])).to eq(['catkey:5678'])
    end

    it 'returns only resolvable identifiers in preferred order when more one is resolvable' do
      expect(described_class.resolvable(['barcode:1234', 'catkey:5678'])).to eq(['catkey:5678', 'barcode:1234'])
    end

    it 'returns an empty array when no resolvable identifiers are found' do
      expect(described_class.resolvable(['bogus:1234', 'nada:5678'])).to eq([])
    end
  end

  describe '#can_resolve?' do
    it 'returns false for an unknown prefix' do
      expect(described_class.send(:'can_resolve?', 'bogus:1234')).to be_falsey
    end

    it 'returns true for barcodes' do
      expect(described_class.send(:'can_resolve?', 'barcode:1234')).to be_truthy
    end

    it 'returns true for catkeys' do
      expect(described_class.send(:'can_resolve?', 'catkey:1234')).to be_truthy
    end
  end

  describe '#fetch' do
    let(:resource) { instance_double(MarcxmlResource, mods: mods) }

    before do
      allow(MarcxmlResource).to receive(:find_by).and_return(resource)
    end

    it 'raises an exception if an unknown metadata type is requested' do
      expect { described_class.fetch('foo:bar') }.to raise_exception(MetadataError)
    end

    it 'raises an exception if an invalid catkey is provided' do
      expect { described_class.fetch('catkey:from server') }.to raise_exception(MetadataError)
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

  describe '#valid_catkey?' do
    it 'receives a number identifier' do
      expect(described_class.send(:valid_catkey?, '12345')).to be_truthy
    end

    it 'receives a colon delimited identifier' do
      expect(described_class.send(:valid_catkey?, '12:34:56:78')).to be_truthy
    end

    it 'receives an invalid identifier' do
      expect(described_class.send(:valid_catkey?, 'from server')).to be_falsey
    end
  end
end
