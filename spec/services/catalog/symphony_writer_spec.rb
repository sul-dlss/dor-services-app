# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::SymphonyWriter do
  subject(:symphony_writer) { described_class.new(marc_records) }

  let(:druid) { 'druid:bc123dg9393' }
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:collection_druid) { 'druid:cc111cc1111' }
  let(:collection_bare_druid) { collection_druid.delete_prefix('druid:') }

  describe '.write_symphony_records' do
    subject(:writer) { symphony_writer.save }

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
        {
          previous_ckeys: [],
          identifier: "8832162\t#{bare_druid}\t",
          indicators: '41',
          subfield_u: "|uhttps://purl.stanford.edu/#{bare_druid}",
          subfield_z: '',
          subfield_x1: '|xSDR-PURL',
          subfield_x2: '|xitem',
          subfield_x4: '|xbarcode:36105216275185',
          subfield_x5: "|xfile:#{bare_druid}%2Fwt183gy6220_00_0001.jp2",
          subfield_x6: "|xcollection:#{collection_bare_druid}:8832162:Collection label & A Special character",
          subfield_x7: '',
          subfield_x8: '|xrights:world'
        }
      end
      let(:marc856) do
        Shellwords.escape("8832162\tbc123dg9393\t.856. 41|uhttps://purl.stanford.edu/bc123dg9393|xSDR-PURL|xitem|xbarcode:36105216275185|xfile:bc123dg9393%2Fwt183gy6220_00_0001.jp2|xcollection:cc111cc1111:8832162:Collection label & A Special character|xrights:world")
      end

      it 'writes the record' do
        expect(File).not_to exist(output_file)
        expect(writer).to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc856}\n"
      end
    end

    context 'when multiple records including special characters' do
      let(:marc_records) do
        {
          previous_ckeys: [
            "123\tbc123dg9393",
            "456\tbc123dg9393"
          ],
          identifier: "8832162\t#{bare_druid}\t",
          indicators: '41',
          subfield_u: "|uhttps://purl.stanford.edu/#{bare_druid}",
          subfield_z: '',
          subfield_x1: '|xSDR-PURL',
          subfield_x2: '|xitem',
          subfield_x4: '|xbarcode:36105216275185',
          subfield_x5: "|xfile:#{bare_druid}%2Fwt183gy6220_00_0001.jp2",
          subfield_x6: "|xcollection:#{collection_bare_druid}:8832162:Collection label & A Special character",
          subfield_x7: '',
          subfield_x8: '|xrights:world'
        }
      end

      it 'writes the record' do
        expect(writer).to be_nil
        expect(File).to exist(output_file)
        file_output = File.read(output_file)
        expect(file_output).to include '123'
        expect(file_output).to include '456'
        expect(file_output).to include '8832162'
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
