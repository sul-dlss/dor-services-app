# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::MarcComparisonService do
  subject(:marc_comparison_service) { described_class.new(sort_field_list_before_comparing:) }

  let(:sort_field_list_before_comparing) { false }
  let(:symphony_catkey) { '666' }

  let(:symphony_marc_hash) do
    { 'leader' => '     ccm a22        4500',
      'fields' =>
      [{ '005' => '19900820141050.0' },
       { '008' => '750409s1961||||enk           ||| | eng' },
       { '010' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '   62039356\\\\72b2' }] } },
       { '040' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'd' => 'OrLoB' }] } },
       { '050' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'M231.B66 Bb maj. 1961' }] } },
       { '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Boccherini, Luigi,' }, { 'd' => '1743-1805.' }] } },
       { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Sonatas,' }, { 'm' => 'cello, continuo,' }, { 'r' => 'B♭ major' }] } },
       { '245' =>
         { 'ind1' => ' ',
           'ind2' => '0',
           'subfields' =>
           [{ 'a' => 'Sonata no. 7, in B flat, for violoncello and piano.' },
            { 'c' =>
              'Edited with realization of the basso continuo by Fritz Spiegl and Walter Bergamnn. Violoncello part edited by Joan Dickson.' }] } },
       { '260' =>
         { 'ind1' => ' ',
           'ind2' => ' ',
           'subfields' => [{ 'a' => 'London, Schott; New York, Associated Music Publishers' }, { 'c' => '[c1961]' }] } },
       { '300' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'score (20 p.) & part.' }, { 'c' => '29cm.' }] } },
       { '490' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Edition [Schott]  10731' }] } },
       { '500' =>
         { 'ind1' => ' ',
           'ind2' => ' ',
           'subfields' =>
           [{ 'a' =>
              "Edited from a recently discovered ms. Closely parallels Gruetzmacher's free arrangement of the Violoncello concerto, G. 482." }] } },
       { '596' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'SAL3' }] } },
       { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Sonatas (Cello and harpsichord)' }] } },
       { '700' =>
         { 'ind1' => '1',
           'ind2' => '2',
           'subfields' =>
           [{ 'a' => 'Boccherini, Luigi,' },
            { 'd' => '1743-1805.' },
            { 't' => 'Concertos,' },
            { 'm' => 'cello, orchestra,' },
            { 'n' => 'G. 482,' },
            { 'r' => 'B♭ major' },
            { 'o' => 'arranged.' }] } },
       { '830' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Edition Schott' }, { 'v' => '10731' }] } },
       { '998' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'SCORE' }] } },
       { '035' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '(OCoLC-M)17708345' }] } },
       { '035' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '(OCoLC-I)268876650' }] } },
       { '918' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '666' }] } },
       { '001' => 'a666' },
       { '003' => 'SIRSI' }] }
  end

  let(:folio_marc_hash) do
    { 'leader' => '01185ccm a2200301   4500',
      'fields' =>
      [{ '005' => '19900820141050.0' },
       { '008' => '750409s1961||||enk           ||| | eng  ' },
       { '010' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '   62039356\\\\72b2' }] } },
       { '040' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'd' => 'OrLoB' }] } },
       { '050' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'M231.B66 Bb maj. 1961' }] } },
       { '100' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Boccherini, Luigi,' }, { 'd' => '1743-1805.' }] } },
       { '240' => { 'ind1' => '1', 'ind2' => '0', 'subfields' => [{ 'a' => 'Sonatas,' }, { 'm' => 'cello, continuo,' }, { 'r' => 'B♭ major' }] } },
       { '245' =>
         { 'ind1' => ' ',
           'ind2' => '0',
           'subfields' =>
           [{ 'a' => 'Sonata no. 7, in B flat, for violoncello and piano.' },
            { 'c' =>
              'Edited with realization of the basso continuo by Fritz Spiegl and Walter Bergamnn. Violoncello part edited by Joan Dickson.' }] } },
       { '260' =>
         { 'ind1' => ' ',
           'ind2' => ' ',
           'subfields' => [{ 'a' => 'London, Schott; New York, Associated Music Publishers' }, { 'c' => '[c1961]' }] } },
       { '300' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'score (20 p.) & part.' }, { 'c' => '29cm.' }] } },
       { '490' => { 'ind1' => '1', 'ind2' => ' ', 'subfields' => [{ 'a' => 'Edition [Schott]  10731' }] } },
       { '500' =>
         { 'ind1' => ' ',
           'ind2' => ' ',
           'subfields' =>
           [{ 'a' =>
              "Edited from a recently discovered ms. Closely parallels Gruetzmacher's free arrangement of the Violoncello concerto, G. 482." }] } },
       { '596' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '31' }] } },
       { '650' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Sonatas (Cello and harpsichord)' }] } },
       { '700' =>
         { 'ind1' => '1',
           'ind2' => '2',
           'subfields' =>
           [{ 'a' => 'Boccherini, Luigi,' },
            { 'd' => '1743-1805.' },
            { 't' => 'Concertos,' },
            { 'm' => 'cello, orchestra,' },
            { 'n' => 'G. 482,' },
            { 'r' => 'B♭ major' },
            { 'o' => 'arranged.' }] } },
       { '830' => { 'ind1' => ' ', 'ind2' => '0', 'subfields' => [{ 'a' => 'Edition Schott' }, { 'v' => '10731' }] } },
       { '998' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'SCORE' }] } },
       { '035' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '(OCoLC-M)17708345' }] } },
       { '035' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '(OCoLC-I)268876650' }] } },
       { '918' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => '666' }] } },
       { '035' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'AAA0675' }] } },
       { '999' =>
         { 'ind1' => 'f',
           'ind2' => 'f',
           'subfields' => [{ 'i' => '696ef04d-1902-5a70-aebf-98d287bce1a1' }, { 's' => '992460aa-bfe6-50ff-93f6-65c6aa786a43' }] } },
       { '001' => 'a666' },
       { '003' => 'FOLIO' }] }
  end

  let(:symphony_marc_obj) { instance_double(MARC::Record, to_hash: symphony_marc_hash, is_a?: true) }
  let(:folio_marc_obj) { instance_double(MARC::Record, to_hash: folio_marc_hash, is_a?: true) }
  let(:mock_symphony_reader) { instance_double(Catalog::SymphonyReader, to_marc: symphony_marc_obj) }
  let(:mock_folio_reader) { instance_double(Catalog::FolioReader, to_marc: folio_marc_obj) }

  let(:expected_marc_hash_diff) do
    [['-', 'fields[12].596.subfields[0]', { 'a' => 'SAL3' }],
     ['+', 'fields[12].596.subfields[0]', { 'a' => '31' }],
     ['+', 'fields[20]', { '035' => { 'ind1' => ' ', 'ind2' => ' ', 'subfields' => [{ 'a' => 'AAA0675' }] } }],
     ['+',
      'fields[21]',
      { '999' =>
        { 'ind1' => 'f',
          'ind2' => 'f',
          'subfields' => [{ 'i' => '696ef04d-1902-5a70-aebf-98d287bce1a1' }, { 's' => '992460aa-bfe6-50ff-93f6-65c6aa786a43' }] } }],
     ['-', 'fields[23]', { '003' => 'SIRSI' }],
     ['+', 'fields[23]', { '003' => 'FOLIO' }],
     ['~', 'leader', '     ccm a22        4500', '01185ccm a2200301   4500']]
  end

  before do
    allow(Catalog::SymphonyReader).to receive(:new).with(catkey: symphony_catkey).and_return(mock_symphony_reader)
    allow(Catalog::FolioReader).to receive(:new).with(folio_instance_hrid: "a#{symphony_catkey}").and_return(mock_folio_reader)
  end

  describe '#diff_marc_for_catkey' do
    it 'returns the expected diff' do
      expect(marc_comparison_service.diff_marc_for_catkey(symphony_catkey:)[:marc_hash_diff]).to eq(expected_marc_hash_diff)
    end
  end

  describe '#diff_marc_for_catkey_list' do
    let(:missing_symphony_catkey) { 777 }
    let(:mock_symphony_reader_missing) { instance_double(Catalog::SymphonyReader) }
    let(:mock_folio_reader_missing) { instance_double(Catalog::FolioReader) }

    before do
      allow(mock_symphony_reader_missing).to receive(:to_marc).and_raise('not found')
      allow(mock_folio_reader_missing).to receive(:to_marc).and_raise('not found')
      allow(Catalog::SymphonyReader).to receive(:new).with(catkey: missing_symphony_catkey).and_return(mock_symphony_reader_missing)
      allow(Catalog::FolioReader).to receive(:new).with(folio_instance_hrid: "a#{missing_symphony_catkey}").and_return(mock_folio_reader_missing)
    end

    it 'breaks out successful and failed diff attempts into separate lists' do
      result = marc_comparison_service.diff_marc_for_catkey_list(symphony_catkey_list: [symphony_catkey, missing_symphony_catkey])
      expect(result[:successful_comparisons].size).to eq 1
      expect(result[:successful_comparisons].first[symphony_catkey]).to eq(expected_marc_hash_diff)
      expect(result[:failed_comparisons].size).to eq 1
      expect(result[:failed_comparisons].first[missing_symphony_catkey][:folio_marc]).to be_a(StandardError)
    end
  end
end
