# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS subject topic <--> cocina mappings' do
  # Note: Subjects with LCSH/NAF authorities are tricky in MODS (and MARC) because there may be a URI for the combined subject
  # string, each individual term, or both. Also, the official MODS documentation says to use authority="lcsh" at the subject
  # level, even when the individual terms have authority="naf": 'If the subject string is formulated according to the
  # Library of Congress Subject Headings (or LC Name Authority File), the value of the authority attribute is "lcsh."
  # A subject thesaurus that does not include names but has an implied authority for names uses the designation for that
  # thesaurus (i.e., "lcsh" means LCSH plus NAF).'[1] This results in apparent inconsistencies, such as pairing
  # authorityURI="http://id.loc.gov/authorities/subjects/" with valueURI="http://id.loc.gov/authorities/names/123",
  # where the authorityURI namespace does not actually include the valueURI. The MODS>COCINA mapping does not represent
  # this conflict, but it is possible to regenerate it from the retained data when mapping COCINA>MODS if desired.
  # [1] http://www.loc.gov/standards/mods/userguide/subject.html

  describe 'Single-term topic subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic>Cats</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Cats',
              type: 'topic'
            }
          ]
        }
      end
    end
  end

  describe 'Multi-term topic etc. subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject>
            <topic>Cats</topic>
            <temporal>1640</temporal>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: '1640',
                  type: 'time'
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Single-term topic subject with authority - option A' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh85021262">
            <topic>Cats</topic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Cats',
              type: 'topic',
              uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Single-term topic subject with authority - option B' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/" valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Cats',
              type: 'topic',
              uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Single-term topic subject with authority - option C' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh85021262">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Cats',
              type: 'topic',
              uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multi-term topic subject with authority for set' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh85021263">
            <topic>Cats</topic>
            <topic>Anatomy</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Cats',
                  type: 'topic'
                },
                {
                  value: 'Anatomy',
                  type: 'topic'
                }
              ],
              uri: 'http://id.loc.gov/authorities/subjects/sh85021263',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multi-term subject with authority but no valueURI' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <topic>Prices</topic>
            <geographic>Great Britain</geographic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Prices',
                  type: 'topic'
                },
                {
                  value: 'Great Britain',
                  type: 'place'
                }
              ],
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multi-term topic subject with authority for terms' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh85021262">Cats</topic>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sj96004895">Behavior</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Cats',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh85021262',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  }
                },
                {
                  value: 'Behavior',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sj96004895',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  }
                }
              ],
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multi-term topic subject with authority for both set and terms' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
            valueURI="http://id.loc.gov/authorities/subjects/sh12345">
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh23456">Horses</topic>
            <topic authority="lcsh" authorityURI="http://id.loc.gov/authorities/subjects/"
              valueURI="http://id.loc.gov/authorities/subjects/sh34567">History</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Horses',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh23456',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  }
                },
                {
                  value: 'History',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh34567',
                  source: {
                    code: 'lcsh',
                    uri: 'http://id.loc.gov/authorities/subjects/'
                  }
                }
              ],
              uri: 'http://id.loc.gov/authorities/subjects/sh12345',
              source: {
                code: 'lcsh',
                uri: 'http://id.loc.gov/authorities/subjects/'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multi-term topic subject with partial authority for both set and terms' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <topic valueURI="http://id.loc.gov/authorities/subjects/sh23456">Horses</topic>
            <topic valueURI="http://id.loc.gov/authorities/subjects/sh34567">History</topic>
          </subject>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <subject authority="lcsh">
            <topic authority="lcsh" valueURI="http://id.loc.gov/authorities/subjects/sh23456">Horses</topic>
            <topic authority="lcsh" valueURI="http://id.loc.gov/authorities/subjects/sh34567">History</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              structuredValue: [
                {
                  value: 'Horses',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh23456',
                  source: {
                    code: 'lcsh'
                  }
                },
                {
                  value: 'History',
                  type: 'topic',
                  uri: 'http://id.loc.gov/authorities/subjects/sh34567',
                  source: {
                    code: 'lcsh'
                  }
                }
              ],
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual subject' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject lang="eng" altRepGroup="1">
            <topic>French New Wave</topic>
          </subject>
          <subject lang="fre" altRepGroup="1">
            <topic>Nouvelle Vague</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              parallelValue: [
                {
                  value: 'French New Wave',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  value: 'Nouvelle Vague',
                  valueLanguage: {
                    code: 'fre',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                }
              ],
              type: 'topic'
            }
          ]
        }
      end
    end
  end

  describe 'Musical genre as topic' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject authority="lcsh">
            <topic>String quartets</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'String quartets',
              type: 'topic',
              source: {
                code: 'lcsh'
              }
            }
          ]
        }
      end
    end
  end

  describe 'Display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <subject displayLabel="This is about">
            <topic>Stuff</topic>
          </subject>
        XML
      end

      let(:cocina) do
        {
          subject: [
            {
              value: 'Stuff',
              type: 'topic',
              displayLabel: 'This is about'
            }
          ]
        }
      end
    end
  end
end
