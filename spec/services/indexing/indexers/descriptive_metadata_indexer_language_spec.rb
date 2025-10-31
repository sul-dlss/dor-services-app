# frozen_string_literal: true

require 'rails_helper'

# TODO: Remove this spec.
RSpec.describe Indexing::Indexers::DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:doc) { indexer.to_solr }
  let(:cocina) do
    build(:dro, id: druid).new(
      description: description.merge(purl: "https://purl.stanford.edu/#{bare_druid}")
    )
  end

  describe 'language mappings from Cocina to Solr sw_language_ssimdv' do
    context 'when language code and text' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'English',
              code: 'eng',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when language code only' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'eng',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when language text only and matches term in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'English',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'includes language term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when language code only and not in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'enk',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'does not include a value' do
        expect(doc).not_to include('sw_language_ssimdv')
      end
    end

    context 'when language text only and not in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'Old English',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'does not include a value' do
        expect(doc).not_to include('sw_language_ssimdv')
      end
    end

    context 'when language code and text, only code in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'Old English',
              code: 'ang',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['English, Old (ca. 450-1100)'])
      end
    end

    context 'when language code and text, only text in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'English, Old (ca. 450-1100)',
              code: 'enk',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'includes text value' do
        expect(doc).to include('sw_language_ssimdv' => ['English, Old (ca. 450-1100)'])
      end
    end

    context 'when language code and text, neither in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'Old English',
              code: 'enk',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'does not include a value' do
        expect(doc).not_to include('sw_language_ssimdv')
      end
    end

    context 'when authority is ISO639-3 and code is in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'American Sign Language',
              code: 'ase',
              source: {
                code: 'iso639-3'
              }
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['American Sign Language'])
      end
    end

    context 'when code with non-ISO639 authority' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'eng',
              source: {
                code: 'rfc5646'
              }
            }
          ]
        }
      end

      it 'defaults to the searchworks language vocabulary' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when no ISO639 authority and language term in mapping' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'English'
            }
          ]
        }
      end

      it 'includes language term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when language and script' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'English',
              code: 'eng',
              source: {
                code: 'iso639-2b'
              },
              script: {
                value: 'Latin',
                code: 'Latn',
                source: {
                  code: 'iso15924'
                }
              }
            }
          ]
        }
      end

      it 'translates language code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when script without language' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              script: {
                value: 'Latin',
                code: 'Latn',
                source: {
                  code: 'iso15924'
                }
              }
            }
          ]
        }
      end

      it 'does not include a value' do
        expect(doc).not_to include('sw_language_ssimdv')
      end
    end

    context 'when same language with multiple scripts' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'Chinese',
              code: 'chi',
              source: {
                code: 'iso639-2b'
              },
              script: {
                value: 'Han (Simplified variant)',
                code: 'Hans',
                source: {
                  code: 'iso15924'
                }
              }
            },
            {
              value: 'Chinese',
              code: 'chi',
              source: {
                code: 'iso639-2b'
              },
              script: {
                value: 'Han (Traditional variant)',
                code: 'Hant',
                source: {
                  code: 'iso15924'
                }
              }
            }
          ]
        }
      end

      it 'translates language code to term and drops duplicate' do
        expect(doc).to include('sw_language_ssimdv' => ['Chinese'])
      end
    end

    context 'when multiple languages' do
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              value: 'English',
              code: 'eng',
              source: {
                code: 'iso639-2b'
              }
            },
            {
              value: 'Russian',
              code: 'rus',
              source: {
                code: 'iso639-2b'
              }
            }
          ]
        }
      end

      it 'includes all languages' do
        expect(doc).to include('sw_language_ssimdv' => %w[English Russian])
      end
    end

    context 'when ISO639-2b authority URI and not authority code' do
      # URI may start with https
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'eng',
              source: {
                uri: 'http://id.loc.gov/vocabulary/iso639-2'
              }
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when ISO639-3 authority URI and not authority code' do
      # URI may start with https
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'ase',
              source: {
                uri: 'http://iso639-3.sil.org/code/'
              }
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['American Sign Language'])
      end
    end

    context 'when ISO639-2 value URI and not authority code' do
      # URI may start with https
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'eng',
              uri: 'http://id.loc.gov/vocabulary/iso639-2/eng'
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['English'])
      end
    end

    context 'when ISO639-3 value URI and not authority code' do
      # URI may start with https
      let(:description) do
        {
          title: [
            {
              value: 'Title'
            }
          ],
          language: [
            {
              code: 'ase',
              uri: 'http://iso639-3.sil.org/code/ase'
            }
          ]
        }
      end

      it 'translates code to term' do
        expect(doc).to include('sw_language_ssimdv' => ['American Sign Language'])
      end
    end
  end
end
