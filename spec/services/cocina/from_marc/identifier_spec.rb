# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Identifier do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with LCCN (010$a)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '010' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [{ 'a' => '  2005203496' }]
            } }
          ]
        }
      end

      it 'returns LCCN with stripped spaces' do
        expect(build).to eq [{ value: '2005203496', type: 'LCCN' }]
      end
    end

    context 'with ISBN (020$aq)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '020' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [
                { 'a' => '9783032051035' },
                { 'q' => '(electronic bk.)' }
              ]
            } }
          ]
        }
      end

      it 'returns ISBN with qualifier' do
        expect(build).to eq [{ value: '9783032051035 (electronic bk.)', type: 'ISBN' }]
      end
    end

    context 'with ISSN (022$a)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '022' => {
              'ind1' => '0', 'ind2' => ' ',
              'subfields' => [
                { 'a' => '3065-7024' },
                { '2' => '1' }
              ]
            } }
          ]
        }
      end

      it 'returns ISSN' do
        expect(build).to eq [{ value: '3065-7024', type: 'ISSN' }]
      end
    end

    context 'with ISRC (024 ind1=0)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '0', 'ind2' => ' ',
              'subfields' => [
                { 'a' => '3065-7024' },
                { 'd' => '1' },
                { 'q' => '(compact disc)' }
              ]
            } }
          ]
        }
      end

      it 'returns ISRC with all subfields' do
        expect(build).to eq [{ value: '3065-7024 1 (compact disc)', type: 'ISRC' }]
      end
    end

    context 'with UPC (024 ind1=1)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { 'a' => '190295849016' }
              ]
            } }
          ]
        }
      end

      it 'returns UPC' do
        expect(build).to eq [{ value: '190295849016', type: 'UPC' }]
      end
    end

    context 'with ISMN (024 ind1=2)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '2', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'M570406210' },
                { 'q' => 'parts' },
                { 'q' => 'sewn' }
              ]
            } }
          ]
        }
      end

      it 'returns ISMN with qualifiers' do
        expect(build).to eq [{ value: 'M570406210 parts sewn', type: 'ISMN' }]
      end
    end

    context 'with International Article Number (024 ind1=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '3', 'ind2' => '0',
              'subfields' => [
                { 'a' => '0190295849016' }
              ]
            } }
          ]
        }
      end

      it 'returns International Article Number' do
        expect(build).to eq [{ value: '0190295849016', type: 'International Article Number' }]
      end
    end

    context 'with SICI (024 ind1=4)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '4', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'a875623247541986340134QTP1' }
              ]
            } }
          ]
        }
      end

      it 'returns SICI' do
        expect(build).to eq [{ value: 'a875623247541986340134QTP1', type: 'SICI' }]
      end
    end

    context 'with unspecified identifier (024 ind1=8)' do
      # See  a11460974
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '8', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'PML 146662.1-82' },
                { 'z' => 'GNR S-659' }
              ]
            } }
          ]
        }
      end

      it 'excludes the identifier' do
        expect(build).to eq []
      end
    end

    context 'with DOI (024 ind1=7, $2=doi)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '7', 'ind2' => ' ',
              'subfields' => [
                { 'a' => '10.1007/978-3-032-05103-5' },
                { '2' => 'doi' }
              ]
            } }
          ]
        }
      end

      it 'returns DOI' do
        expect(build).to eq [{ value: '10.1007/978-3-032-05103-5', type: 'DOI' }]
      end
    end

    context 'with source code (024 ind1=7, non-DOI)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '024' => {
              'ind1' => '7', 'ind2' => ' ',
              'subfields' => [
                { 'a' => '0A3200912B4A1057' },
                { '2' => 'istc' }
              ]
            } }
          ]
        }
      end

      it 'returns identifier with source code' do
        expect(build).to eq [{ value: '0A3200912B4A1057', source: { code: 'istc' } }]
      end
    end

    context 'with issue number (028 ind1=0)' do
      # See a10778545
      let(:marc_hash) do
        {
          'fields' => [
            { '028' => {
              'ind1' => '0', 'ind2' => '2',
              'subfields' => [
                { 'a' => '162' },
                { 'b' => 'Columbia' }
              ]
            } },
            { '028' => {
              'ind1' => '0', 'ind2' => '0',
              'subfields' => [
                { 'a' => '67962-D' },
                { 'b' => 'Columbia' }
              ]
            } },
            { '028' => {
              'ind1' => '0', 'ind2' => '0',
              'subfields' => [
                { 'a' => '67963-D' },
                { 'b' => 'Columbia' }
              ]
            } },
            { '028' => {
              'ind1' => '0', 'ind2' => '0',
              'subfields' => [
                { 'a' => '67964-D' },
                { 'b' => 'Columbia' }
              ]
            } }

          ]
        }
      end

      it 'returns issue numbers' do
        expect(build).to eq [
          { value: '162 Columbia', type: 'issue number' },
          { value: '67962-D Columbia', type: 'issue number' },
          { value: '67963-D Columbia', type: 'issue number' },
          { value: '67964-D Columbia', type: 'issue number' }
        ]
      end
    end

    context 'with matrix number (028 ind1=1)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '028' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'J-18961M-A' },
                { 'b' => 'Country Line' }
              ]
            } }
          ]
        }
      end

      it 'returns matrix number' do
        expect(build).to eq [{ value: 'J-18961M-A Country Line', type: 'matrix number' }]
      end
    end

    context 'with music plate number (028 ind1=2)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '028' => {
              'ind1' => '2', 'ind2' => '2',
              'subfields' => [
                { 'a' => 'B. & H. 8797' },
                { 'b' => 'Breitkopf & Hartel' }
              ]
            } }
          ]
        }
      end

      it 'returns music plate number' do
        expect(build).to eq [{ value: 'B. & H. 8797 Breitkopf & Hartel', type: 'music plate' }]
      end
    end

    context 'with music publisher number (028 ind1=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '028' => {
              'ind1' => '3', 'ind2' => '2',
              'subfields' => [
                { 'a' => '12345' },
                { 'b' => 'Columbia' }
              ]
            } }
          ]
        }
      end

      it 'returns music publisher number' do
        expect(build).to eq [{ value: '12345 Columbia', type: 'music publisher' }]
      end
    end

    context 'with videorecording publisher number (028 ind1=4)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '028' => {
              'ind1' => '4', 'ind2' => '2',
              'subfields' => [
                { 'a' => '440 073 032-9' },
                { 'b' => 'Deutsche Grammophon' },
                { 'q' => '(set and guide)' }
              ]
            } }
          ]
        }
      end

      it 'returns videorecording publisher number' do
        expect(build).to eq [{ value: '440 073 032-9 Deutsche Grammophon (set and guide)' }]
      end
    end
  end
end
