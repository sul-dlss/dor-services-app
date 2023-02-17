# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SymphonyWriter do
  subject(:symphony_writer) { described_class.new }

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
      let(:marc_records) { ['abcdef'] }

      it 'writes the record' do
        expect(File).not_to exist(output_file)
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'when multiple records including special characters' do
      let(:marc_records) { %w[ab!#cdef 12@345 thirdrecord'withquote fourthrecordwith"doublequote] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records[0]}\n#{marc_records[1]}\n#{marc_records[2]}\n#{marc_records[3]}\n"
      end
    end

    context 'when an empty array' do
      let(:marc_records) { [] }

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

    context 'when a record with single quotes' do
      let(:marc_records) { ["this is | a record | that has 'single quotes' in it | and it should work"] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end

    context 'when a record with double and single quotes' do
      let(:marc_records) { ['record with "double quotes" in it | and it should work'] }

      it 'writes the record' do
        expect(writer).not_to be_nil
        expect(File).to exist(output_file)
        expect(File.read(output_file)).to eq "#{marc_records.first}\n"
      end
    end
  end
end
