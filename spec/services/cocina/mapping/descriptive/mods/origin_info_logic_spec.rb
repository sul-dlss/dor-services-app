# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo <--> cocina mappings LOGIC' do
  describe 'Multiple date types, no event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <dateIssued>1930</dateIssued>
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <originInfo eventType="publication">
          <dateIssued>1930</dateIssued>
        </originInfo>
        <originInfo eventType="copyright">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'publication',
            date: [
              {
                value: '1930'
              }
            ]
          },
          {
            type: 'copyright',
            date: [
              {
                value: '1929'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Multiple date types, matching event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo eventType="publication">
          <dateIssued>1930</dateIssued>
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <originInfo eventType="publication">
          <dateIssued>1930</dateIssued>
        </originInfo>
        <originInfo eventType="copyright">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'publication',
            date: [
              {
                value: '1930'
              }
            ]
          },
          {
            type: 'copyright',
            date: [
              {
                value: '1929'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Single date type, nonmatching event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo eventType="publication">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'publication',
            date: [
              {
                value: '1929',
                type: 'copyright'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Single dateOther, nonmatching event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo type="production">
          <dateOther type="development">1930</dateOther>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'production',
            date: [
              {
                value: '1930',
                type: 'development'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'No date, no event type, publication subelements' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <publisher>Virago</publisher>
          <edition>1st edition</edition>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <originInfo eventType="publication">
          <publisher>Virago</publisher>
          <edition>1st edition</edition>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
        </originInfo>
      XML
    end
  end

  describe 'dateCreated, no event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <dateCreated>1930</dateCreated>
        </originInfo>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <originInfo eventType="creation">
          <dateCreated>1930</dateCreated>
        </originInfo>{
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'creation',
            date: [
              {
                value: '1930'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'dateOther with type, no event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <dateOther type="acquisition">1930</dateOther>
        </originInfo>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <originInfo eventType="acquisition">
          <dateOther>1930</dateOther>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'acquisition',
            date: [
              {
                value: '1930'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Only place subelement, no event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <place>
            <placeTerm type="text">San Francisco, Calif.</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            location: [
              {
                value: 'San Francisco, Calif.'
              }
            ]
          }
        ]
      }
    end

    let(:warnings) do
      Notification.new(msg: 'Undetermined event type')
    end
  end

  describe 'Multiple date types, additional publication subelements' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <dateIssued>1930</dateIssued>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
          <edition>1st edition</edition>
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:roundtrip_mods) do
      <<~XML
        <originInfo eventType="publication">
          <dateIssued>1930</dateIssued>
          <place>
            <placeTerm type="text">London</placeTerm>
          </place>
          <edition>1st edition</edition>
        </originInfo>
        <originInfo eventType="copyright">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'publication',
            date: [
              {
                value: '1930'
              }
            ],
            location: [
              {
                value: 'London'
              }
            ],
            note: [
              {
                value: '1st edition',
                type: 'edition'
              }
            ]
          },
          {
            type: 'copyright',
            date: [
              {
                value: '1929'
              }
            ]
          }
        ]
      }
    end
  end

  describe 'Unmapped event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo eventType="deaccession">
          <dateOther>1930</dateOther>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            type: 'deaccession',
            date: [
              {
                value: '1930'
              }
            ]
          }
        ]
      }
    end

    let(:warnings) do
      Notification.new(msg: 'Unmapped event type')
    end
  end

  describe 'No event type' do
    xit 'check implementation'

    let(:mods) do
      <<~XML
        <originInfo>
          <dateOther>1930</dateOther>
        </originInfo>
      XML
    end

    let(:cocina) do
      {
        event: [
          {
            date: [
              {
                value: '1930'
              }
            ]
          }
        ]
      }
    end

    let(:warnings) do
      Notification.new(msg: 'Undetermined event type')
    end
  end
end
