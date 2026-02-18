# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::ModsService do
  let(:mods_service) { described_class.new(marc_service:) }

  let(:marc_service) { instance_double(Catalog::MarcService, marcxml_ng: marc_ng) }
  let(:marc_record) do
    MARC::Record.new.tap do |record|
      record << MARC::DataField.new('245', '1', '0', ['a', 'Gaudy night /'], ['c', 'by Dorothy L. Sayers.'])
    end
  end
  let(:marc_ng) do
    Nokogiri::XML(marc_record.to_xml.to_s)
  end

  describe '#mods' do
    let(:mods) do
      <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.loc.gov/mods/v3" version="3.7" xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd">
          <titleInfo usage="primary">
            <title>Gaudy night</title>
          </titleInfo>
          <typeOfResource/>
          <originInfo/>
          <note type="statement of responsibility">by Dorothy L. Sayers.</note>
          <recordInfo>
            <recordOrigin>Converted from MARCXML to MODS version 3.7 using\n\t\t\t\tMARC21slim2MODS3-7_SDR_v2-8.xsl (SUL 3.7 version 2.8 20251217; LC Revision 1.140\n\t\t\t\t20200717)</recordOrigin>
          </recordInfo>
        </mods>
      XML
    end

    before do
      allow(described_class).to receive(:new).and_call_original
    end

    it 'returns MODS XML from FOLIO MARC record' do
      described_class.mods(marc_service:)
      expect(described_class).to have_received(:new).with(marc_service:)
      expect(mods_service.mods).to eq mods
    end
  end
end
