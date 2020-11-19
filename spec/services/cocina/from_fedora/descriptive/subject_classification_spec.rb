# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Subject do
  subject(:build) { described_class.build(resource_element: ng_xml.root) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  # 1. Classification with authority
  context 'when given a classification with authority' do
    let(:xml) { '<classification authority="lcc">G9801.S12 2015 .Z3</classification>' }

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'classification',
          "value": 'G9801.S12 2015 .Z3',
          "source": {
            "code": 'lcc'
          }
        }
      ]
    end
  end

  # 2. Classification with edition
  context 'when given a classification with edition' do
    let(:xml) { '<classification authority="ddc" edition="11">683</classification>' }

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'classification',
          "value": '683',
          "source": {
            "code": 'ddc',
            "version": '11th edition'
          }
        }
      ]
    end
  end

  # 3. Display label
  context 'when given a classification with authority' do
    let(:xml) { '<classification authority="lcc" displayLabel="Library of Congress classification">ML410.B3</classification>' }

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'classification',
          "value": 'ML410.B3',
          "displayLabel": 'Library of Congress classification',
          "source": {
            "code": 'lcc'
          }
        }
      ]
    end
  end

  context 'when given multiple classifications' do
    let(:xml) do
      <<~XML
        <classification authority="ddc" edition="11">683</classification>
        <classification authority="ddc" edition="12">684</classification>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'classification',
          "value": '683',
          "source": {
            "code": 'ddc',
            "version": '11th edition'
          }
        },
        {
          "type": 'classification',
          "value": '684',
          "source": {
            "code": 'ddc',
            "version": '12th edition'
          }
        }

      ]
    end
  end
end
