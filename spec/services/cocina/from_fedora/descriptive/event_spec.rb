# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Event do
  subject(:build) { described_class.build(ng_xml) }

  let(:ng_xml) do
    Nokogiri::XML <<~XML
      <mods xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns="http://www.loc.gov/mods/v3" version="3.6"
        xsi:schemaLocation="http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd">
        #{xml}
      </mods>
    XML
  end

  context 'with a simple dateCreated' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated>1980</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1980'
            }
          ]
        }
      ]
    end
  end

  context 'with a simple dateIssued (with encoding)' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued encoding="w3cdtf">1928</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1928',
              "encoding": {
                "code": 'w3cdtf'
              }
            }
          ]
        }
      ]
    end
  end

  context 'with a single copyrightDate' do
    let(:xml) do
      <<~XML
        <originInfo>
          <copyrightDate>1930</copyrightDate>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'copyright',
          "date": [
            {
              "value": '1930'
            }
          ]
        }
      ]
    end
  end

  context 'with a single dateCaptured (ISO 8601 encoding, keyDate)' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCaptured keyDate="yes" encoding="iso8601">20131012231249</dateCaptured>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'capture',
          "date": [
            {
              "value": '20131012231249',
              "encoding": {
                "code": 'iso8601'
              },
              "status": 'primary'
            }
          ]
        }
      ]
    end
  end

  context 'with a single dateOther' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateOther type="Islamic">1441 AH</dateOther>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "date": [
            {
              "value": '1441 AH',
              "note": [
                {
                  "value": 'Islamic',
                  "type": 'date type'
                }
              ]
            }
          ]
        }
      ]
    end
  end

  context 'with a date range' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated keyDate="yes" point="start">1920</dateCreated>
          <dateCreated point="end">1925</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "structuredValue": [
                {
                  "value": '1920',
                  "type": 'start',
                  "status": 'primary'
                },
                {
                  "value": '1925',
                  "type": 'end'
                }
              ]
            }
          ]
        }
      ]
    end
  end

  context 'with an approximate date' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateCreated qualifier="approximate">1940</dateCreated>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'creation',
          "date": [
            {
              "value": '1940',
              "qualifier": 'approximate'
            }
          ]
        }
      ]
    end
  end

  context 'with a range plus single date' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued keyDate="yes" point="start">1940</dateIssued>
          <dateIssued point="end">1945</dateIssued>
          <dateIssued>1948</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "structuredValue": [
                {
                  "value": '1940',
                  "type": 'start',
                  "status": 'primary'
                },
                {
                  "value": '1945',
                  "type": 'end'
                }
              ]
            },
            {
              "value": '1948'
            }
          ]
        }
      ]
    end
  end

  context 'with multiple single dates' do
    let(:xml) do
      <<~XML
        <originInfo>
          <dateIssued keyDate="yes">1940</dateIssued>
          <dateIssued>1942</dateIssued>
        </originInfo>
      XML
    end

    it 'builds the cocina data structure' do
      expect(build).to eq [
        {
          "type": 'publication',
          "date": [
            {
              "value": '1940',
              "status": 'primary'
            },
            {
              "value": '1942'
            }
          ]
        }
      ]
    end
  end
end
