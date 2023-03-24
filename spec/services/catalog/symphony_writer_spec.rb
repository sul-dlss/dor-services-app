# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::SymphonyWriter do
  subject(:symphony_writer) { described_class.new(cocina_object:, marc_856_data:) }

  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection_bare_druid) { collection_druid.delete_prefix('druid:') }

  let(:marc_856_data) do
    {
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
  end

  describe '.save' do
    let(:fixtures) { './spec/fixtures' }
    let(:output_file) do
      "#{fixtures}/sdr_purl/sdr-purl-856s"
    end

    let(:cocina_object) { build(:dro, id: druid).new(identification:) }
    let(:release_data) { true }

    before do
      Settings.release.symphony_path = "#{fixtures}/sdr_purl"
      allow(ReleaseTags).to receive(:released_to_searchworks?).and_return(release_data)
    end

    after do
      FileUtils.rm_f(output_file)
    end

    context 'when a single catkey that has been released to Searchworks' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'symphony',
              catalogRecordId: '8832162'
            }
          ]
        }
      end

      let(:marc856_file) do
        "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:world"
      end

      it 'writes the record' do
        expect(File).not_to exist(output_file)
        symphony_writer.save
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856_file}\n"
      end
    end

    context 'when a single catkey that has not been released to Searchworks' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'symphony',
              catalogRecordId: '8832162'
            }
          ]
        }
      end

      let(:release_data) { false }

      let(:marc856_file) do
        "8832162\tbc123dg9393\t"
      end

      it 'writes the record' do
        expect(File).not_to exist(output_file)
        symphony_writer.save
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856_file}\n"
      end
    end

    context 'when previous and current catkeys (including special characters)' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'previous symphony',
              catalogRecordId: '8832160'
            },
            {
              catalog: 'previous symphony',
              catalogRecordId: '8832161'
            },
            {
              catalog: 'symphony',
              catalogRecordId: '8832162'
            }
          ]
        }
      end

      let(:marc_856_data) do
        {
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
      end
      let(:marc856_file) do
        [
          "8832160\tbc123dg9393\t",
          "8832161\tbc123dg9393\t",
          "8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xlabel:we call this a 'part'|xsort:123|xrights:world"
        ]
      end

      it 'writes the record' do
        symphony_writer.save
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856_file[0]}\n#{marc856_file[1]}\n#{marc856_file[2]}\n"
      end
    end

    context 'when onlt previous catkeys' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: [
            {
              catalog: 'previous symphony',
              catalogRecordId: '8832160'
            },
            {
              catalog: 'previous symphony',
              catalogRecordId: '8832161'
            }
          ]
        }
      end

      let(:marc_856_data) do
        {
          indicators: '41',
          subfields: [
            { code: 'z', value: nil }
          ]
        }
      end
      let(:marc856_file) do
        [
          "8832160\tbc123dg9393\t",
          "8832161\tbc123dg9393\t"
        ]
      end

      it 'writes the record' do
        symphony_writer.save
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856_file[0]}\n#{marc856_file[1]}\n"
      end
    end

    context 'when no catalog links' do
      let(:identification) do
        {
          sourceId: 'sul:8832162',
          catalogLinks: []
        }
      end

      it 'does nothing' do
        symphony_writer.save
        expect(File).not_to exist(output_file)
      end
    end
  end
end
