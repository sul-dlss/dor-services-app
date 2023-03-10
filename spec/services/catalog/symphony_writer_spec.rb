# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::SymphonyWriter do
  subject(:symphony_writer) { described_class.new }

  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection_bare_druid) { collection_druid.delete_prefix('druid:') }

  describe '.write_symphony_records' do
    subject(:writer) { symphony_writer.save marc_records }

    let(:fixtures) { './spec/fixtures' }
    let(:output_file) do
      "#{fixtures}/sdr_purl/sdr-purl-856s"
    end

    before do
      Settings.release.symphony_path = "#{fixtures}/sdr_purl"
    end

    after do
      FileUtils.rm_f(output_file)
    end

    context 'when a single record' do
      let(:marc_records) do
        [
          {
            catalog_record_id: '8832162',
            druid: bare_druid,
            indicators: '41',
            subfields: [
              { code: 'z', value: nil },
              { code: 'u', value: "https://purl.stanford.edu/#{bare_druid}" },
              { code: 'x', value: 'SDR-PURL' },
              { code: 'x', value: 'item' },
              { code: 'x', value: 'barcode:36105216275185' },
              { code: 'x', value: "file:#{bare_druid}%2Fwt183gy6220_00_0001.jp2" },
              { code: 'x', value: "collection:#{collection_bare_druid}:8832162:Collection label & A Special character" },
              { code: 'x', value: nil },
              { code: 'x', value: 'rights:world' }
            ]
          }
        ]
      end
      let(:marc856_file) do
        "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:world"
      end

      it 'writes the record' do
        expect(File).not_to exist(output_file)
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856_file}\n"
      end
    end

    context 'when multiple records including special characters' do
      let(:marc_records) do
        [
          {
            catalog_record_id: '123',
            druid: bare_druid
          },
          {
            catalog_record_id: '456',
            druid: bare_druid
          },
          {
            catalog_record_id: '8832162',
            druid: bare_druid,
            indicators: '41',
            subfields: [
              { code: 'z', value: nil },
              { code: 'u', value: "https://purl.stanford.edu/#{bare_druid}" },
              { code: 'x', value: 'SDR-PURL' },
              { code: 'x', value: 'item' },
              { code: 'x', value: 'barcode:36105216275185' },
              { code: 'x', value: "file:#{bare_druid}%2Fwt183gy6220_00_0001.jp2" },
              { code: 'x', value: "collection:#{collection_bare_druid}:8832162:Collection label & A Special character" },
              { code: 'x', value: "label:we call this a 'part'" },
              { code: 'x', value: 'sort:123' },
              { code: 'x', value: 'rights:world' }
            ]
          }
        ]
      end
      let(:marc856_file) do
        [
          "123\tbc123dg9393\t",
          "456\tbc123dg9393\t",
          "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xlabel:we call this a 'part'|xsort:123|xrights:world"
        ]
      end

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856_file[0]}\n#{marc856_file[1]}\n#{marc856_file[2]}\n"
      end
    end

    context 'when an empty array' do
      let(:marc_records) { {} }

      it 'does nothing' do
        expect(writer).to be_nil
        expect(File).not_to exist(output_file)
      end
    end

    context 'when nil' do
      let(:marc_records) { nil }

      it 'does nothing' do
        expect(writer).to be_nil
        expect(File).not_to exist(output_file)
      end
    end
  end
end
