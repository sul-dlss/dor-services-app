# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::SearchworksFormatIndexer do
  subject(:value) { described_class.value(cocina_display_record:) }

  context 'without hrid' do
    let(:cocina_display_record) do
      instance_double(CocinaDisplay::CocinaRecord, folio_hrid: nil,
                                                   searchworks_resource_types: ['Archived website', 'manuscript'])
    end

    it { is_expected.to eq ['Archived website', 'manuscript'] }
  end

  context 'with hrid but no cached marc' do
    let(:cocina_display_record) do
      instance_double(CocinaDisplay::CocinaRecord, folio_hrid: 'a123',
                                                   searchworks_resource_types: ['Archived website', 'manuscript'])
    end

    it { is_expected.to eq ['Archived website', 'manuscript'] }
  end

  context 'with hrid and cached marc' do
    let(:cocina_display_record) do
      instance_double(CocinaDisplay::CocinaRecord, folio_hrid: 'a123')
    end

    let(:result) { { field => value } }
    let(:field) { 'field' }

    before do
      MarcCacheEntry.create(folio_hrid: 'a123', marc_data: record.to_json_string)
    end

    # These scenarios are copied from:
    # https://github.com/sul-dlss/searchworks_traject_indexer/blob/93e091eec3d195e92a3ec8229338c47cfe300475/spec/lib/traject/config/folio_format_config_spec.rb#L22
    context 'when record is a Manuscript' do
      context 'when leader[6] = p' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = 'p1952cpm  2200457Ia 4500'
          end
        end

        it 'maps to Archive/Manuscript' do
          expect(result[field]).to eq ['Archive/Manuscript']
        end
      end

      context 'when leader[6] = a and leader[7] = c' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = 'p1952cac  2200457Ia 4500'
          end
        end

        it 'maps to Archive/Manuscript' do
          expect(result[field]).to eq ['Archive/Manuscript']
        end
      end

      context 'when 245h contains manuscript or manuscript/digital' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '01952c d  2200457Ia 4500'
            # We expect [manuscript] to be in brackets in the string
            r.append(MARC::DataField.new('245', '1', ' ',
                                         MARC::Subfield.new('a', 'manuscript: 245h'),
                                         MARC::Subfield.new('h', '[manuscript/digital]')))
          end
        end

        it 'maps to Archive/Manuscript' do
          expect(result[field]).to eq ['Archive/Manuscript']
        end
      end
    end

    context 'when record is a Book' do
      context 'when leader[6] = a and leader[7] = m' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = 'p1952cam  2200457Ia 4500'
          end
        end

        it 'maps to Book' do
          expect(result[field]).to eq ['Book']
        end
      end

      context 'when leader[7] = s and 008[21] = m' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = 'p1952cas  2200457Ia 4500'
            r.append(MARC::ControlField.new('008', '000000000000000000000m000000000000000000'))
          end
        end

        it 'maps to Book' do
          expect(result[field]).to eq ['Book']
        end
      end

      context 'when 006[0] = s and 006[4] = m' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.append(MARC::ControlField.new('006', 's000m00000000000000'))
          end
        end

        it 'maps to Book' do
          expect(result[field]).to eq ['Book']
        end
      end
    end

    context 'when record is a Database' do
      context 'when leader[7] = s and 008[21] = d' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '0000000s0000000000000000'
            r.append(MARC::ControlField.new('008', '000000000000000000000d000000000000000000'))
          end
        end

        it 'maps to Database' do
          expect(result[field]).to eq ['Database']
        end
      end

      context 'when 006[0] = s and 006[4] = d' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.append(MARC::ControlField.new('006', 's000d00000000000000'))
          end
        end

        it 'maps to Database' do
          expect(result[field]).to eq ['Database']
        end
      end

      context 'when leader[6] = m and 008[26] = j' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000m00000000000000000'
            r.append(MARC::ControlField.new('008', '00000000000000000000000000j00000000000'))
          end
        end

        it 'maps to Database' do
          expect(result[field]).to eq ['Database']
        end
      end
    end

    context 'when record is a Dataset' do
      context 'when leader[6] = m and 008[26] = a' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000m00000000000000000'
            r.append(MARC::ControlField.new('008', '00000000000000000000000000a00000000000'))
          end
        end

        it 'maps to Dataset' do
          expect(result[field]).to eq ['Dataset']
        end
      end
    end

    # TODO: Need to stub FOLIO record/holdings.
    # Then test Equipment and Video/Film|Blu-ray

    context 'when record is an Image' do
      context 'when leader[6] = k and 008[33] matches [aciklnopst 0-9|]' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000k00000000000000000'
            r.append(MARC::ControlField.new('008', '000000000000000000000000000000000a0000'))
          end
        end

        it 'maps to Image' do
          expect(result[field]).to eq ['Image']
        end
      end

      context 'when leader[6] = g and 008[33] matches [ aciklnopst]' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000g00000000000000000'
            r.append(MARC::ControlField.new('008', '000000000000000000000000000000000k0000'))
          end
        end

        it 'maps to Image' do
          expect(result[field]).to eq ['Image']
        end
      end

      context 'when record is an Image based on 245h terms' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000a00000000000000000'
            r.append(MARC::DataField.new('245', '1', ' ',
                                         MARC::Subfield.new('a', 'Example title'),
                                         MARC::Subfield.new('h', 'This is a technical drawing')))
          end
        end

        it 'maps to Image' do
          expect(result[field]).to eq ['Image']
        end
      end

      context 'when the 245h term contains a partial string match' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000a00000000000000000'
            r.append(MARC::DataField.new('245', '1', ' ',
                                         MARC::Subfield.new('a', 'Example title'),
                                         MARC::Subfield.new('h', 'technical')))
          end
        end

        it 'does not map to Image' do
          expect(result[field]).not_to eq ['Image']
        end
      end

      context 'when record is an Image based on 007 and 245h = kit' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000a00000000000000000'
            r.append(MARC::ControlField.new('007', 'k0000000000'))
            r.append(MARC::DataField.new('245', '1', ' ',
                                         MARC::Subfield.new('a', 'Example kit title'),
                                         MARC::Subfield.new('h', 'kit')))
          end
        end

        it 'maps to Image' do
          expect(result[field]).to eq ['Image']
        end
      end

      context 'when record is an Image|Photo' do
        context 'when 007[0] = k and 007[1] in [g, h, r, v]' do
          let(:record) do
            MARC::Record.new.tap do |r|
              r.leader = '000000a00000000000000000'
              r.append(MARC::ControlField.new('007', 'kg0000000000'))
            end
          end

          it 'maps to Image|Photo' do
            expect(result[field]).to eq ['Image', 'Image|Photo']
          end
        end
      end

      context 'when record is an Image|Poster' do
        context 'when 007[0] = k and 007[1] = k' do
          let(:record) do
            MARC::Record.new.tap do |r|
              r.leader = '000000a00000000000000000'
              r.append(MARC::ControlField.new('007', 'kk0000000000'))
            end
          end

          it 'maps to Image|Poster' do
            expect(result[field]).to eq ['Image', 'Image|Poster']
          end
        end
      end

      context 'when record is an Image|Slide' do
        context 'when 007[0] = g and 007[1] = s' do
          let(:record) do
            MARC::Record.new.tap do |r|
              r.leader = '000000a00000000000000000'
              r.append(MARC::ControlField.new('007', 'gs0000000000'))
            end
          end

          it 'maps to Image|Slide' do
            expect(result[field]).to eq ['Image', 'Image|Slide']
          end
        end
      end
    end

    context 'when the match is based on regex matching in a MARC subfield' do
      context 'when 338h term contains piano roll terms' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000a00000000000000000'
            r.append(MARC::DataField.new('338', '1', ' ',
                                         MARC::Subfield.new('a',
                                                            'This is a sentence containing the phrase piano roll')))
          end
        end

        it 'maps to Sound recording|Piano/Organ roll' do
          expect(result[field]).to eq ['Sound recording', 'Sound recording|Piano/Organ roll']
        end
      end

      context 'when 245n contains video terms' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000000000000000000000'
            r.append(MARC::DataField.new('245', '1', ' ',
                                         MARC::Subfield.new('n', 'A set of video recordings')))
          end
        end

        it 'maps to Video/Film' do
          expect(result[field]).to eq ['Video/Film']
        end
      end

      context 'when 538a contains blu-ray terms' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000000000000000000000'
            r.append(MARC::DataField.new('538', '1', ' ',
                                         MARC::Subfield.new('a', 'A set of blu-ray discs')))
          end
        end

        it 'maps to Video/Film' do
          expect(result[field]).to eq ['Video/Film', 'Video/Film|Blu-ray']
        end
      end
    end

    context 'when record is Software/Multimedia' do
      context 'when leader[6] = m and 008 is missing' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000m00000000000000000'
          end
        end

        it 'maps to Software/Multimedia' do
          expect(result[field]).to eq ['Software/Multimedia']
        end
      end

      context 'when leader[6] = m and 008[26] is not a/g/j' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000m00000000000000000'
            # 26th position (index 25) = 'z', which is not in excluded_values
            r.append(MARC::ControlField.new('008', '00000000000000000000000000z00000000000'))
          end
        end

        it 'maps to Software/Multimedia' do
          expect(result[field]).to eq ['Software/Multimedia']
        end
      end

      # If 008[26] is a, g, or j, it should not map to Software/Multimedia
      context 'when leader[6] = m and 008[26] is j' do
        let(:record) do
          MARC::Record.new.tap do |r|
            r.leader = '000000m00000000000000000'
            r.append(MARC::ControlField.new('008', '00000000000000000000000000j00000000000'))
          end
        end

        # In this case it is covered by another rule
        it 'does not map to Software/Multimedia' do
          expect(result[field]).to eq ['Database']
        end
      end
    end
  end
end
