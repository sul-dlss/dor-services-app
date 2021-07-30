# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS originInfo place <--> cocina mappings' do
  describe 'Place - text (authorized)' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="text" authority="naf" authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
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
                  value: 'Stanford (Calif.)',
                  uri: 'http://id.loc.gov/authorities/names/n50046557',
                  source: {
                    code: 'naf',
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Place - code' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/"
                valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              location: [
                {
                  code: 'cau',
                  uri: 'http://id.loc.gov/vocabulary/countries/cau',
                  source: {
                    code: 'marccountry',
                    uri: 'http://id.loc.gov/vocabulary/countries/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Place - text and code in same place element' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              location: [
                {
                  value: 'California',
                  code: 'cau',
                  uri: 'http://id.loc.gov/vocabulary/countries/cau',
                  source: {
                    code: 'marccountry',
                    uri: 'http://id.loc.gov/vocabulary/countries/'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Place - text and code in same place element, different authority on each' do
    # based on druid:kn689tm8699
    xit 'not implemented - placeTerm in same place element with different authority' do
      let(:mods) do
        <<~XML
          <originInfo displayLabel="Place of creation" eventType="production">
            <place>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries" valueURI="http://id.loc.gov/vocabulary/countries/xxu">xxu</placeTerm>
              <placeTerm type="text" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo displayLabel="Place of creation" eventType="production">
            <place>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries" valueURI="http://id.loc.gov/vocabulary/countries/xxu">xxu</placeTerm>
            </place>
            <place>
              <placeTerm type="text" authorityURI="http://id.loc.gov/authorities/names" valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              displayLabel: 'Place of creation',
              location: [
                {
                  code: 'xxu',
                  uri: 'http://id.loc.gov/vocabulary/countries/xxu',
                  source: {
                    code: 'marccountry',
                    uri: 'http://id.loc.gov/vocabulary/countries'
                  }
                },
                {
                  value: 'Stanford (Calif.)',
                  uri: 'http://id.loc.gov/authorities/names/n50046557',
                  source: {
                    uri: 'http://id.loc.gov/authorities/names'
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Place - text and code in different place elements' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry">enk</placeTerm>
            </place>
            <place>
              <placeTerm type="text">London</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              location: [
                {
                  code: 'enk',
                  source: {
                    code: 'marccountry'
                  }
                },
                {
                  value: 'London'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # NOTE: this case is being handled with a report and bad data.  When merged with main branch, take what is in main branch
  # describe 'Place - text and code for different places - Version B (from replayable spreadsheet, incorrect MODS)' do
  #   # The authority value goes with the code term and the authorityURI and valueURI values go with the text term.
  #
  #   xit 'not implemented: text and code for diff places from replayable spreadsheet' do
  #     let(:mods) do
  #       <<~XML
  #         <originInfo eventType="publication">
  #           <place>
  #             <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/"
  #               valueURI="http://id.loc.gov/authorities/names/n50046557">cau</placeTerm>
  #             <placeTerm type="text" authority="marccountry" authorityURI="http://id.loc.gov/authorities/names/"
  #               valueURI="http://id.loc.gov/authorities/names/n50046557">Stanford (Calif.)</placeTerm>
  #           </place>
  #         </originInfo>
  #       XML
  #     end
  #
  #     let(:cocina) do
  #       {
  #         event: [
  #           {
  #             type: 'publication',
  #             location: [
  #               {
  #                 code: 'cau',
  #                 source: {
  #                   code: 'marccountry'
  #                 }
  #               },
  #               {
  #                 value: 'Stanford (Calif.)',
  #                 uri: 'http://id.loc.gov/authorities/names/n50046557',
  #                 source: {
  #                   uri: 'http://id.loc.gov/authorities/names/'
  #                 }
  #               }
  #             ]
  #           }
  #         ]
  #       }
  #     end
  #   end
  # end

  describe 'Supplied place name' do
    # Adapted from druid:bv279kp1172
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="production" displayLabel="Place of creation">
            <place supplied="yes">
              <placeTerm authorityURI="http://id.loc.gov/authorities/names/"
                valueURI="http://id.loc.gov/authorities/names/n81127564" type="text">Selma (Ala.)</placeTerm>
            </place>
            <dateCreated keyDate="yes" encoding="w3cdtf">1965</dateCreated>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'production',
              displayLabel: 'Place of creation',
              location: [
                {
                  type: 'supplied',
                  value: 'Selma (Ala.)',
                  uri: 'http://id.loc.gov/authorities/names/n81127564',
                  source: {
                    uri: 'http://id.loc.gov/authorities/names/'
                  }
                }
              ],
              date: [
                {
                  value: '1965',
                  type: 'creation',
                  encoding: {
                    code: 'w3cdtf'
                  },
                  status: 'primary'
                }
              ]
            }
          ]
        }
      end
    end
  end

  # Bad data handling

  describe 'Place - code with bad authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marcountry" authorityURI="http://id.loc.gov/vocabulary/countries/"
                valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <originInfo eventType="publication">
            <place>
              <placeTerm type="code" authority="marccountry" authorityURI="http://id.loc.gov/vocabulary/countries/"
                valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'publication',
              location: [
                {
                  code: 'cau',
                  uri: 'http://id.loc.gov/vocabulary/countries/cau',
                  source: {
                    code: 'marccountry',
                    uri: 'http://id.loc.gov/vocabulary/countries/'
                  }
                }
              ]
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'marcountry authority code (should be marccountry)')] }
    end
  end

  describe 'Place code missing authority' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="code">xxu</placeTerm>
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
                  code: 'xxu'
                }
              ]
            }
          ]
        }
      end

      let(:warnings) { [Notification.new(msg: 'Place code missing authority', context: { code: 'xxu' })] }
    end
  end

  # specs added by devs below

  context 'when cocina event location with code missing source, but has URI' do
    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              location: [
                {
                  code: 'cau',
                  uri: 'http://id.loc.gov/vocabulary/countries/cau'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="code" valueURI="http://id.loc.gov/vocabulary/countries/cau">cau</placeTerm>
            </place>
          </originInfo>
        XML
      end
    end
  end

  context 'when cocina event location with value missing source, but has URI' do
    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
      let(:cocina) do
        {
          event: [
            {
              location: [
                {
                  value: 'California',
                  uri: 'http://id.loc.gov/vocabulary/countries/cau'
                }
              ]
            }
          ]
        }
      end

      let(:mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="text" valueURI="http://id.loc.gov/vocabulary/countries/cau">California</placeTerm>
            </place>
          </originInfo>
        XML
      end
    end
  end

  context 'when place, publisher and eventType manufacture' do
    # based on vy980tx4948
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo eventType="manufacture">
            <place>
              <placeTerm type="text">Germany</placeTerm>
            </place>
            <publisher>Germany</publisher>
          </originInfo>
        XML
      end

      let(:cocina) do
        {
          event: [
            {
              type: 'manufacture',
              location: [
                {
                  value: 'Germany'
                }
              ],
              contributor: [
                {
                  name: [
                    {
                      value: 'Germany'
                    }
                  ],
                  role: [
                    {
                      value: 'manufacturer',
                      code: 'mfr',
                      uri: 'http://id.loc.gov/vocabulary/relators/mfr',
                      source: {
                        code: 'marcrelator',
                        uri: 'http://id.loc.gov/vocabulary/relators/'
                      }
                    }
                  ],
                  type: 'organization'
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'when place with empty elements' do
    # based on nc238hg8745, yt337yg7382
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <originInfo>
            <publisher/>
            <place>
              <placeTerm type="text">Unknown</placeTerm>
            </place>
            <dateCreated/>
          </originInfo>
        XML
      end

      # empty elements removed
      let(:roundtrip_mods) do
        <<~XML
          <originInfo>
            <place>
              <placeTerm type="text">Unknown</placeTerm>
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
                  value: 'Unknown'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'placeTerm code xx with authority marccountry' do
    context 'when code alone' do
      # based on cf040mt0946, dm283vh3332, fn474tc0101, gq289jf7762, hm986jh6778, jg916mx8338
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <place>
                <placeTerm type="code" authority="marccountry">xx</placeTerm>
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
                    code: 'xx',
                    source: {
                      code: 'marccountry'
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end

    context 'when single place element with code and text' do
      # based on cf040mt0946, dm283vh3332, fn474tc0101, gq289jf7762, hm986jh6778, jg916mx8338
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <originInfo>
              <place>
                <placeTerm type="code" authority="marccountry">xx</placeTerm>
                <placeTerm type="text">Place of publication not identified]</placeTerm>
              </place>
            </originInfo>
          XML
        end

        # authority="marccountry" added to text placeTerm
        let(:roundtrip_mods) do
          <<~XML
            <originInfo>
              <place>
                <placeTerm type="code" authority="marccountry">xx</placeTerm>
                <placeTerm type="text" authority="marccountry">Place of publication not identified]</placeTerm>
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
                    value: 'Place of publication not identified]',
                    code: 'xx',
                    source: {
                      code: 'marccountry'
                    }
                  }
                ]
              }
            ]
          }
        end
      end
    end
  end
end
