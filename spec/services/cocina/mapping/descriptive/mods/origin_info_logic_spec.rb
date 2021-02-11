# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/OverwritingSetup
# TODO: remove these rubocop exceptions when implementation uncomments spec lines, but keep the one above
# rubocop:disable Layout/CommentIndentation
# rubocop:disable Layout/IndentationConsistency
RSpec.describe 'MODS originInfo <--> cocina mappings LOGIC' do
  describe 'Multiple date types, no event type' do
    let(:my_roundtrip_mods) do
      <<~XML
        <originInfo eventType="publication">
          <dateIssued>1930</dateIssued>
        </originInfo>
        <originInfo eventType="copyright">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateIssued>1930</dateIssued>
            <copyrightDate>1929</copyrightDate>
          </originInfo>
        XML
      end
      let(:roundtrip_mods) { my_roundtrip_mods }
      let(:cocina) { my_cocina }
    end

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_roundtrip_mods }
    end
  end

  describe 'Multiple date types, matching event type' do
    let(:my_roundtrip_mods) do
      <<~XML
        <originInfo eventType="publication">
          <dateIssued>1930</dateIssued>
        </originInfo>
        <originInfo eventType="copyright">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <dateIssued>1930</dateIssued>
            <copyrightDate>1929</copyrightDate>
          </originInfo>
        XML
      end
      let(:roundtrip_mods) { my_roundtrip_mods }
      let(:cocina) { my_cocina }
    end

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_roundtrip_mods }
    end
  end

  describe 'Single date type, nonmatching event type' do
    xit 'to be implemented'

    let(:my_mods) do
      <<~XML
        <originInfo eventType="publication">
          <copyrightDate>1929</copyrightDate>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) { my_mods }
      let(:cocina) { my_cocina }
    # end

    # it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_mods }
    # end
  end

  describe 'Single dateOther, nonmatching event type' do
    xit 'to be implemented'

    let(:my_mods) do
      <<~XML
        <originInfo eventType="production">
          <dateOther type="development">1930</dateOther>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) { my_mods }
      let(:cocina) { my_cocina }
    # end

    # it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_mods }
    # end
  end

  describe 'No date, no event type, publication subelements' do
    let(:my_roundtrip_mods) do
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

    let(:my_cocina) do
      {
        event: [
          {
            type: 'publication',
            contributor: [
              {
                name: [
                  {
                    value: 'Virago'
                  }
                ],
                type: 'organization',
                role: [
                  {
                    value: 'publisher',
                    code: 'pbl',
                    uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                    source: {
                      code: 'marcrelator',
                      uri: 'http://id.loc.gov/vocabulary/relators/'
                    }
                  }
                ]
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
          }
        ]
      }
    end

    it_behaves_like 'MODS cocina mapping' do
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
      let(:roundtrip_mods) { my_roundtrip_mods }
      let(:cocina) { my_cocina }
    end

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_roundtrip_mods }
    end
  end

  describe 'dateCreated, no event type' do
    xit 'to be implemented'

    let(:my_roundtrip_mods) do
      <<~XML
        <originInfo eventType="creation">
          <dateCreated>1930</dateCreated>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateCreated>1930</dateCreated>
          </originInfo>
        XML
      end
      let(:roundtrip_mods) { my_roundtrip_mods }
      let(:cocina) { my_cocina }
    # end

    # it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_roundtrip_mods }
    # end
  end

  describe 'dateOther with type, no event type' do
    xit 'to be implemented: MODS cocina mapping'

    let(:my_roundtrip_mods) do
      <<~XML
        <originInfo eventType="acquisition">
          <dateOther>1930</dateOther>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <dateOther type="acquisition">1930</dateOther>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) { my_roundtrip_mods }

      let(:cocina) { my_cocina }
    # end

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_roundtrip_mods }
    end
  end

  describe 'Only place subelement, no event type' do
    xit 'to be implemented'

    let(:my_mods) do
      <<~XML
        <originInfo>
          <place>
            <placeTerm type="text">San Francisco, Calif.</placeTerm>
          </place>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) { my_mods }
      let(:cocina) { my_cocina }
      let(:warnings) { [Notification.new(msg: 'Undetermined event type')] }
    # end

    # it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_mods }
    # end
  end

  describe 'Multiple date types, additional publication subelements' do
    let(:my_roundtrip_mods) do
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

    let(:my_cocina) do
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

    it_behaves_like 'MODS cocina mapping' do
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

      let(:roundtrip_mods) { my_roundtrip_mods }
      let(:cocina) { my_cocina }
    end

    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_roundtrip_mods }
    end
  end

  describe 'Unmapped event type' do
    xit 'to be implemented'

    let(:my_mods) do
      <<~XML
        <originInfo eventType="deaccession">
          <dateOther>1930</dateOther>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) { my_mods }
      let(:cocina) { my_cocina }
      let(:warnings) { [Notification.new(msg: 'Unmapped event type')] }
    # end

    # it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_mods }
    # end
  end

  describe 'No event type' do
    xit 'to be implemented: warning message'

    let(:my_mods) do
      <<~XML
        <originInfo>
          <dateOther>1930</dateOther>
        </originInfo>
      XML
    end

    let(:my_cocina) do
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

    # it_behaves_like 'MODS cocina mapping' do
      let(:mods) { my_mods }
      let(:cocina) { my_cocina }
      let(:warnings) { [Notification.new(msg: 'Undetermined event type')] }
    # end

    # it_behaves_like 'cocina MODS mapping' do
      let(:cocina) { my_cocina }
      let(:mods) { my_mods }
      let(:warnings) { [Notification.new(msg: 'Undetermined event type')] }
    # end
  end
end
# rubocop:enable RSpec/OverwritingSetup
# rubocop:enable Layout/CommentIndentation
# rubocop:enable Layout/IndentationConsistency
