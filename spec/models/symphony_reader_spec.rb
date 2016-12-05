require 'rails_helper'

RSpec.describe SymphonyReader do
  subject(:reader) { described_class.new(catkey: catkey) }
  let(:catkey) { 'catkey' }

  describe '#to_marc' do
    before do
      FakeWeb.register_uri(:get, Settings.CATALOG.SYMPHONY.JSON_URL % { catkey: catkey }, body: body.to_json)
    end

    let(:body) do
      {
        fields: {
          bib: {
            leader: '00956cem 2200229Ma 4500',
            fields: [
              { tag: '001', subfields: [{ code: '_', data: 'some data' }] },
              { tag: '001', subfields: [{ code: '_', data: 'some data' }] },
              {
                tag: '245',
                inds: '41',
                subfields: [{ code: 'a', data: 'some data' }]
              }
            ]
          }
        }
      }
    end
    it 'converts symphony json to marc records' do
      expect(reader.to_marc).to be_a_kind_of MARC::Record
    end

    it 'parses leader information' do
      expect(reader.to_marc.leader).to eq '00956cem 2200229Ma 4500'
    end

    it 'parses control fields' do
      expect(reader.to_marc.fields('001').first.value).to eq 'some data'
    end

    it 'removes duplicate fields' do
      expect(reader.to_marc.fields('001').length).to eq 1
    end

    it 'parses data fields' do
      field = reader.to_marc.fields('245').first
      expect(field.indicator1).to eq '4'
      expect(field.indicator2).to eq '1'
      expect(field.subfields.first.code).to eq 'a'
      expect(field.subfields.first.value).to eq 'some data'
    end
  end
end
