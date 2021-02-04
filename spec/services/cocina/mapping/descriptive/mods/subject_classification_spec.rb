# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject classification <--> cocina mappings' do
  describe 'Classification with authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <classification authority="lcc">G9801.S12 2015 .Z3</classification>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'classification',
              value: 'G9801.S12 2015 .Z3',
              source: {
                code: 'lcc'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Classification without authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <classification>G9801.S12 2015 .Z3</classification>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'classification',
              value: 'G9801.S12 2015 .Z3'
            }
          ]
        }
      end

      let(:warnings) do
        [
          Notification.new(msg: 'No source given for classification value', context: { value: 'G9801.S12 2015 .Z3' })
        ]
      end
    end
  end

  describe 'Classification with edition' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <classification authority="ddc" edition="11">683</classification>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'classification',
              value: '683',
              source: {
                code: 'ddc',
                version: '11th edition'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Classification with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <classification authority="lcc" displayLabel="Library of Congress classification">ML410.B3</classification>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'classification',
              value: 'ML410.B3',
              displayLabel: 'Library of Congress classification',
              source: {
                code: 'lcc'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multiple classifications' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <classification authority="ddc" edition="11">683</classification>
          <classification authority="ddc" edition="12">684</classification>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              type: 'classification',
              value: '683',
              source: {
                code: 'ddc',
                version: '11th edition'
              }
            },
            {
              type: 'classification',
              value: '684',
              source: {
                code: 'ddc',
                version: '12th edition'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multiple classifications, one primary' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <classification usage="primary" authority="ddc" edition="11">683</classification>
        <classification authority="ddc" edition="12">684</classification>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            type: 'classification',
            value: '683',
            usage: 'primary',
            source: {
              code: 'ddc',
              version: '11th edition'
            }
          },
          {
            type: 'classification',
            value: '684',
            source: {
              code: 'ddc',
              version: '12th edition'
            }
          }
        ]
      }
    end
  end

  # Bad data handling

  describe 'Multiple classifications, multiple primary' do
    xit 'not implemented'

    let(:mods) do
      <<~XML
        <classification usage="primary" authority="ddc" edition="11">683</classification>
        <classification usage="primary" authority="ddc" edition="12">684</classification>
      XML
    end

    let(:roundtrip_mods) do
      # Drop all instances of usage="primary" after first one
      <<~XML
        <classification usage="primary" authority="ddc" edition="11">683</classification>
        <classification authority="ddc" edition="12">684</classification>
      XML
    end

    let(:cocina) do
      {
        subject: [
          {
            type: 'classification',
            value: '683',
            usage: 'primary',
            source: {
              code: 'ddc',
              version: '11th edition'
            }
          },
          {
            type: 'classification',
            value: '684',
            source: {
              code: 'ddc',
              version: '12th edition'
            }
          }
        ]
      }
    end

    let(:warnings) do
      [
        Notification.new(msg: 'Multiple classifications marked as primary')
      ]
    end
  end
end
