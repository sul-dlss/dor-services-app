# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'MODS note <--> cocina mappings' do
  describe 'Simple note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note>This is a note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a note.'
            }
          ]
        }
      end
    end
  end

  describe 'Note with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note type="preferred citation">This is the preferred citation.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is the preferred citation.',
              type: 'preferred citation'
            }
          ]
        }
      end
    end
  end

  describe 'Note with type "abstract"' do
    xit 'not implemented' do
      let(:mods) do
        <<~XML
          <note type="abstract">This is an abstract.</note>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract>This is an abstract.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is an abstract',
              type: 'abstract'
            }
          ]
        }
      end
    end
  end

  describe 'Note with other type associated with abstract' do
    # other abstract type values: scope and content, summary
    # these types round trip to abstract regardless of displayLabel value
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note type="summary">This is a note.</note>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract type="summary">This is a note.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a note.',
              type: 'summary'
            }
          ]
        }
      end
    end
  end

  describe 'Note with type associated with abstract, nonstandard capitalization' do
    # abstract type values: abstract, scope and content, summary
    # these types round trip to abstract regardless of displayLabel value
    # TODO: these specific values should be downcased (but not note type in general)
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note type="Summary">This is a note.</note>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract type="summary">This is a note.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a note.',
              type: 'summary'
            }
          ]
        }
      end
    end
  end

  describe 'Note with display label' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note displayLabel="Conservation note">This is a conservation note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a conservation note.',
              displayLabel: 'Conservation note'
            }
          ]
        }
      end
    end
  end

  describe 'Note with display label associated with abstract' do
    # abstract display label values:
    # Abstract, Content advice, Review, Scope and content, Subject, Summary
    # these display labels round trip to to abstract regardless of type value
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note displayLabel="Scope and content">This is a scope and content note.</note>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract displayLabel="Scope and content">This is a scope and content note.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a scope and content note.',
              displayLabel: 'Scope and content'
            }
          ]
        }
      end
    end
  end

  describe 'Note with display label associated with abstract, nonstandard capitalization' do
    # abstract display label values:
    # Abstract, Content advice, Review, Scope and content, Subject, Summary
    # TODO: these specific values should be downcased after the first letter (but not note displayLabel in general)
    # these display labels round trip to to abstract regardless of type value
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note displayLabel="Scope and Content">This is a scope and content note.</note>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract displayLabel="Scope and content">This is a scope and content note.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a scope and content note.',
              displayLabel: 'Scope and content'
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual note' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note lang="eng" altRepGroup="1">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              parallelValue: [
                {
                  value: 'This is a note.',
                  valueLanguage: {
                    code: 'eng',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                },
                {
                  value: "C'est une note.",
                  valueLanguage: {
                    code: 'fre',
                    source: {
                      code: 'iso639-2b'
                    }
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Multilingual note with type' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note type="reproduction">Microfilm. 1 reel. (Chen Cheng colletion reel no. 14)</note>
          <note type="statement of responsibility" altRepGroup="1" script="Latn">Zhong yang jun shi zheng zhi xue xiao bian.</note>
          <note type="statement of responsibility" altRepGroup="1" script="Latn">中央軍事政治學校編.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'Microfilm. 1 reel. (Chen Cheng colletion reel no. 14)',
              type: 'reproduction'
            },
            {
              parallelValue: [
                {
                  type: 'statement of responsibility',
                  value: 'Zhong yang jun shi zheng zhi xue xiao bian.',
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                },
                {
                  type: 'statement of responsibility',
                  value: '中央軍事政治學校編.',
                  valueLanguage: {
                    valueScript: {
                      code: 'Latn',
                      source: {
                        code: 'iso15924'
                      }
                    }
                  }
                }
              ]
            }
          ]
        }
      end
    end
  end

  describe 'Link to external value only' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note xlink:href="http://note.org/note" />
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              valueAt: 'http://note.org/note'
            }
          ]
        }
      end
    end
  end

  describe 'Note with ID attribute' do
    # Adapted from dn184gm5872
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note displayLabel="Model Year" ID="model_year">1934</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: '1934',
              displayLabel: 'Model Year',
              identifier: [
                {
                  value: 'model_year',
                  type: 'anchor'
                }
              ]
            }
          ]
        }
      end
    end
  end

  ## Data error - do not warn
  describe 'Note with unmatched altRepGroup' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note type="statement of responsibility" altRepGroup="00">by Dorothy L. Sayers</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'by Dorothy L. Sayers',
              type: 'statement of responsibility'
            }
          ]
        }
      end

      let(:roundtrip_mods) do
        <<~XML
          <note type="statement of responsibility">by Dorothy L. Sayers</note>
        XML
      end
    end
  end

  # devs added specs below

  context 'with a multilingual note with a script for one language' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <note lang="eng" altRepGroup="1" script="Latn">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              parallelValue: [
                {
                  value: 'This is a note.',
                  valueLanguage:
                    {
                      code: 'eng',
                      source: {
                        code: 'iso639-2b'
                      },
                      valueScript: {
                        code: 'Latn',
                        source: {
                          code: 'iso15924'
                        }
                      }
                    }
                },
                {
                  value: "C'est une note.",
                  valueLanguage:
                    {
                      code: 'fre',
                      source: {
                        code: 'iso639-2b'
                      }
                    }
                }
              ]
            }
          ]
        }
      end
    end

    # NOTE: cocina -> MODS
    it_behaves_like 'cocina MODS mapping' do
      let(:mods) do
        <<~XML
          <note lang="eng" altRepGroup="1" script="Latn">This is a note.</note>
          <note lang="fre" altRepGroup="1">C'est une note.</note>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              parallelValue: [
                {
                  value: 'This is a note.',
                  valueLanguage:
                    {
                      code: 'eng',
                      source: {
                        code: 'iso639-2b'
                      },
                      valueScript: {
                        code: 'Latn',
                        source: {
                          code: 'iso15924'
                        }
                      }
                    }
                },
                {
                  value: "C'est une note.",
                  valueLanguage:
                    {
                      code: 'fre',
                      source: {
                        code: 'iso639-2b'
                      }
                    }
                }
              ]
            }
          ]
        }
      end
    end
  end

  context 'with an empty displayLabel' do
    it_behaves_like 'MODS cocina mapping' do
      let(:mods) do
        <<~XML
          <abstract displayLabel="">This is a synopsis.</abstract>
        XML
      end

      let(:roundtrip_mods) do
        <<~XML
          <abstract>This is a synopsis.</abstract>
        XML
      end

      let(:cocina) do
        {
          note: [
            {
              value: 'This is a synopsis.',
              type: 'abstract'
            }
          ]
        }
      end
    end
  end

  context 'when note is various flavors of missing' do
    context 'when cocina note is empty array' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            note: []
          }
        end

        let(:roundtrip_cocina) do
          {
          }
        end

        let(:mods) { '' }
      end
    end

    context 'when MODS has no elements' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) { '' }

        let(:cocina) do
          {
          }
        end
      end
    end

    context 'when cocina note is array with empty hash' do
      # NOTE: cocina -> MODS
      it_behaves_like 'cocina MODS mapping' do
        let(:cocina) do
          {
            note: [{}]
          }
        end

        let(:roundtrip_cocina) do
          {
          }
        end

        let(:mods) do
          <<~XML
            <note/>
          XML
        end
      end
    end

    context 'when MODS is empty note element with no attributes' do
      it_behaves_like 'MODS cocina mapping' do
        let(:mods) do
          <<~XML
            <note/>
          XML
        end

        let(:roundtrip_mods) do
          <<~XML
          XML
        end

        let(:cocina) do
          {
          }
        end
      end
    end
  end
end
