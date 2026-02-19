# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Note do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:require_title) { true }
    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with a statement of responsibility (245$c)' do
      # See in00000144356
      let(:marc_hash) do
        {
          'fields' => [
            { '245' => {
              'ind1' => '1',
              'ind2' => '0',
              'subfields' => [
                {
                  'c' => 'Nicholas A. Robinson, Elizabeth Burleson, Lin-Heng Lye, and Kirk W. Junker, editors'
                }
              ]
            } }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'statement of responsibility',
          value: 'Nicholas A. Robinson, Elizabeth Burleson, Lin-Heng Lye, and Kirk W. Junker, editors'
        }]
      end
    end

    context 'with a statement of responsibility in multiple scripts (245$c/880)' do
      # See a13162356
      let(:marc_hash) do
        {
          'fields' => [
            {
              '245' => {
                'ind1' => '1',
                'ind2' => '0',
                'subfields' => [
                  {
                    '6' => '880-01'
                  },
                  {
                    'c' => 'S.A. Smagina.'
                  }
                ]
              }
            },
            {
              '880' => {
                'ind1' => '1',
                'ind2' => '0',
                'subfields' => [
                  {
                    '6' => '245-02'
                  },
                  {
                    'c' => 'С.А. Смагина.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [
          {
            type: 'statement of responsibility',
            value: 'S.A. Smagina.'
          },
          {
            type: 'statement of responsibility',
            value: 'С.А. Смагина.'
          }
        ]
      end
    end

    context 'with dates of publication (362$az)' do
      # Based on in00000144356
      let(:marc_hash) do
        {
          'fields' => [
            {
              '362' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Began with: 2024-1 edition, issued in May 2024.'
                  },
                  {
                    'z' => 'Cf. New serial titles.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'date/sequential designation',
          value: 'Began with: 2024-1 edition, issued in May 2024. Cf. New serial titles.'
        }]
      end
    end

    context 'with general note (500$a3)' do
      # Based on a11408080
      let(:marc_hash) do
        {
          'fields' => [
            {
              '500' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Applies to part:'
                  },
                  {
                    'a' => 'Welte-Mignon licensee roll.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Applies to part: Welte-Mignon licensee roll.'
        }]
      end
    end

    context 'with with note (501$a)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '501' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'With a separately titled map on same sheet: Queen Maud Range.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'With a separately titled map on same sheet: Queen Maud Range.'
        }]
      end
    end

    context 'with dissertation note (502$bcdgo)' do
      # Based on in00000870077
      let(:marc_hash) do
        {
          'fields' => [
            {
              '502' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'g' => 'Thesis'
                  },
                  {
                    'b' => 'Ph.D.'
                  },
                  {
                    'c' => 'Stanford University'
                  },
                  {
                    'd' => '2026'
                  },
                  {
                    'o' => '1234'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'thesis',
          value: 'Thesis Ph.D. Stanford University 2026 1234'
        }]
      end
    end

    context 'with bibliography note (504$ab)' do
      # Based on in00000144356
      let(:marc_hash) do
        {
          'fields' => [
            {
              '504' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Includes bibliographical references.'
                  },
                  {
                    'b' => '10'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'bibliography',
          value: 'Includes bibliographical references. 10'
        }]
      end
    end

    context 'with table of contents (505$agrtu) - variant 1' do
      # See a13708310
      let(:marc_hash) do
        {
          'fields' => [
            {
              '505' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Acknowledgments / David Bacon -- Preface / Roberto Trujillo and Benjamin L. Stone -- ' \
                           'Placing the Bacon Archive in Stanford\'s Special Collections / Benjamin L. Stone -- ' \
                           'Tarps, tents and bush: the worker art of David Bacon / Jose Padilla -- ' \
                           'Introduction / Michael A. Keller -- Farm workers -- Immigrant workers -- Mexico -- ' \
                           'Migration and the border -- Poverty and social protest -- From Davao to Baghdad -- ' \
                           'Excerpts from an Interview with David Bacon / Meredith Blasingame'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'table of contents',
          value: 'Acknowledgments / David Bacon -- Preface / Roberto Trujillo and Benjamin L. Stone -- ' \
                 'Placing the Bacon Archive in Stanford\'s Special Collections / Benjamin L. Stone -- ' \
                 'Tarps, tents and bush: the worker art of David Bacon / Jose Padilla -- ' \
                 'Introduction / Michael A. Keller -- Farm workers -- Immigrant workers -- Mexico -- ' \
                 'Migration and the border -- Poverty and social protest -- From Davao to Baghdad -- ' \
                 'Excerpts from an Interview with David Bacon / Meredith Blasingame'
        }]
      end
    end

    context 'with table of contents (505$agrtu) - variant 2' do
      # Based on LC examples
      let(:marc_hash) do
        {
          'fields' => [
            {
              '505' => {
                'ind1' => '0',
                'ind2' => '0',
                'subfields' => [
                  {
                    't' => 'Quatrain II'
                  },
                  {
                    'g' => '(16:35) --'
                  },
                  {
                    't' => 'Water ways'
                  },
                  {
                    'g' => '(1:57) /'
                  },
                  {
                    'r' => 'by L. H. Fellows.'
                  },
                  {
                    'u' => 'http://lcweb.loc.gov/catdir/toc/99176484.html'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'table of contents',
          value: 'Quatrain II (16:35) -- Water ways (1:57) / by L. H. Fellows. http://lcweb.loc.gov/catdir/toc/99176484.html'
        }]
      end
    end

    context 'with restrictions on access (506$abcdefgqu3) - variant 1' do
      # See a14723913
      let(:marc_hash) do
        {
          'fields' => [
            {
              '506' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'SD cards are not available in original format, and have been reformatted to a digital use copy. ' \
                           'Digital copies of SD card contents are available online in the Field Reading Room at Green Library or ' \
                           'by contacting specialcollections@stanford.edu.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'access restriction',
          value: 'SD cards are not available in original format, and have been reformatted to a digital use copy. Digital copies of SD card contents are available online in the Field Reading Room at Green Library or by contacting specialcollections@stanford.edu.'
        }]
      end
    end

    context 'with restrictions on access (506$abcdefgqu3) - variant 2' do
      # Constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '506' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Applies to part:'
                  },
                  {
                    'a' => 'Terms governing access.'
                  },
                  {
                    'b' => 'Jurisdiction.'
                  },
                  {
                    'c' => 'Physical access provisions.'
                  },
                  {
                    'd' => 'Authorized users.'
                  },
                  {
                    'e' => 'Authorization.'
                  },
                  {
                    'f' => 'Standard terminology.'
                  },
                  {
                    'g' => 'Availability date.'
                  },
                  {
                    'q' => 'Supplying agency.'
                  },
                  {
                    'u' => 'URI'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'access restriction',
          value: 'Applies to part: Terms governing access. Jurisdiction. Physical access provisions. Authorized users. Authorization. Standard terminology. Availability date. Supplying agency. URI'
        }]
      end
    end

    context 'with scale note for visual materials (507$ab)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '507' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Scale 1:500,000;'
                  },
                  {
                    'b' => '1 in. equals 8 miles.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Scale 1:500,000; 1 in. equals 8 miles.'
        }]
      end
    end

    context 'with creation/production credits (508$a3)' do
      # Based on a14655722
      let(:marc_hash) do
        {
          'fields' => [
            {
              '508' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Applies to part:'
                  },
                  {
                    'a' => 'Directors, S.A. Hanan, Surbhi Dewan ; producers, Surbhi Dewan, Afia Mushtaq ; director of photography, Faisal Bhat ; editors, Tenzin Kunchok, Surbhi Dewan'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'creation/production credits',
          value: 'Applies to part: Directors, S.A. Hanan, Surbhi Dewan ; producers, Surbhi Dewan, Afia Mushtaq ; director of photography, Faisal Bhat ; editors, Tenzin Kunchok, Surbhi Dewan'
        }]
      end
    end

    context 'with citation/references (510$abcux3) - variant 1' do
      # See a11408080
      let(:marc_hash) do
        {
          'fields' => [
            {
              '510' => {
                'ind1' => '4',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Smith, Charles Davis & Richard J. Howe. The Welte-Mignon, 1994,'
                  },
                  {
                    'c' => 'page 275.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'citation/reference',
          value: 'Smith, Charles Davis & Richard J. Howe. The Welte-Mignon, 1994, page 275.'
        }]
      end
    end

    context 'with citation/references (510$abcux3) - variant 2' do
      # Based on LC examples
      let(:marc_hash) do
        {
          'fields' => [
            {
              '510' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Index Medicus,'
                  },
                  {
                    'x' => '0019-3879,'
                  },
                  {
                    'b' => 'v1n1, 1984-'
                  },
                  {
                    'u' => 'URI'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'citation/reference',
          value: 'Index Medicus, 0019-3879, v1n1, 1984- URI'
        }]
      end
    end

    context 'with participant or performer (511$a3)' do
      # See a11408080
      let(:marc_hash) do
        {
          'fields' => [
            {
              '511' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Applies to part:'
                  },
                  {
                    'a' => 'Austin Conradi, piano.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'performers',
          value: 'Applies to part: Austin Conradi, piano.'
        }]
      end
    end

    context 'with type of report and period covered (513$ab)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '513' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Quarterly technical progress report;'
                  },
                  {
                    'b' => 'Jan.-Apr. 1, 1977.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Quarterly technical progress report; Jan.-Apr. 1, 1977.'
        }]
      end
    end

    context 'with data quality (514$abcdefghijkmuz)' do
      # Constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '514' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Attribute report.'
                  },
                  {
                    'b' => 'Attribute value.'
                  },
                  {
                    'c' => 'Attribute explanation.'
                  },
                  {
                    'd' => 'Logical report.'
                  },
                  {
                    'e' => 'Completeness report.'
                  },
                  {
                    'f' => 'Horizontal report.'
                  },
                  {
                    'g' => 'Horizontal value.'
                  },
                  {
                    'h' => 'Horizontal explanation.'
                  },
                  {
                    'i' => 'Vertical report.'
                  },
                  {
                    'j' => 'Vertical value.'
                  },
                  {
                    'k' => 'Vertical explanation.'
                  },
                  {
                    'm' => 'Cloud cover.'
                  },
                  {
                    'u' => 'URI.'
                  },
                  {
                    'z' => 'Display note.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Attribute report. Attribute value. Attribute explanation. Logical report. Completeness report. Horizontal report. Horizontal value. Horizontal explanation. Vertical report. Vertical value. Vertical explanation. Cloud cover. URI. Display note.'
        }]
      end
    end

    context 'with numbering peculiarities (515$a)' do
      # See in00000144356
      let(:marc_hash) do
        {
          'fields' => [
            {
              '515' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Issued in 3 volumes, 2024-'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'numbering',
          value: 'Issued in 3 volumes, 2024-'
        }]
      end
    end

    context 'with type of computer file or data (516$a)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '516' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Computer programs.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Computer programs.'
        }]
      end
    end

    context 'with date/time and place of an event (518$adop3) - variant 1' do
      # See a12365535
      let(:marc_hash) do
        {
          'fields' => [
            {
              '518' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'o' => 'Recorded'
                  },
                  {
                    'd' => '2015 August 28-September 4'
                  },
                  {
                    'p' => 'Opéra national de Lyon.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'venue',
          value: 'Recorded 2015 August 28-September 4 Opéra national de Lyon.'
        }]
      end
    end

    context 'with date/time and place of an event (518$adop3) - variant 2' do
      # Based on LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '518' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Applies to part:'
                  },
                  {
                    'a' => 'Filmed on location in Rome and Venice from January through June 1976.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'venue',
          value: 'Applies to part: Filmed on location in Rome and Venice from January through June 1976.'
        }]
      end
    end

    context 'with summary (520$abcu3 ind1 not 4) - variant 1' do
      # See in00000022114
      let(:marc_hash) do
        {
          'fields' => [
            {
              '520' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Student journal of the 2023 Stanford University Sophomore College course, BIO10SC, ' \
                           '"Natural History, Marine Biology, and Research" based at Hopkins Marine Station. ' \
                           'The course explored the biology of Monterey Bay and the artistic and political history of the region'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'summary',
          value: 'Student journal of the 2023 Stanford University Sophomore College course, BIO10SC, ' \
                 '"Natural History, Marine Biology, and Research" based at Hopkins Marine Station. ' \
                 'The course explored the biology of Monterey Bay and the artistic and political history of the region'
        }]
      end
    end

    context 'with summary (520$abcu3 ind1 not 4) - variant 2' do
      # Constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '520' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Applies to part:'
                  },
                  {
                    'a' => 'Summary.'
                  },
                  {
                    'b' => 'Expansion.'
                  },
                  {
                    'c' => 'Assigning source.'
                  },
                  {
                    'u' => 'URI'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'summary',
          value: 'Applies to part: Summary. Expansion. Assigning source. URI'
        }]
      end
    end

    context 'with content advisory (520 ind1=4 $abcu3)' do
      # Constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '520' => {
                'ind1' => '4',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Content warning: Contains racist imagery.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'content warning',
          value: 'Content warning: Contains racist imagery.'
        }]
      end
    end

    context 'with target audience (521$a[b3])' do
      # See a13674772
      let(:marc_hash) do
        {
          'fields' => [
            {
              '521' => {
                'ind1' => '8',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'MPAA rating: R; for some nudity and sexuality'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'target audience',
          value: 'MPAA rating: R; for some nudity and sexuality'
        }]
      end
    end

    context 'with geographic coverage (522$a)' do
      # See a11655929
      let(:marc_hash) do
        {
          'fields' => [
            {
              '522' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Only covers a portion of the Coconino National Forest.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Only covers a portion of the Coconino National Forest.'
        }]
      end
    end

    context 'with preferred citation (524$a3)' do
      # See a14394621
      let(:marc_hash) do
        {
          'fields' => [
            {
              '524' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => '[identification of item], Afghan oral history collection (M2871). Dept. of Special Collections and University Archives, Stanford University Libraries, Stanford, California.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'preferred citation',
          value: '[identification of item], Afghan oral history collection (M2871). Dept. of Special Collections and University Archives, Stanford University Libraries, Stanford, California.'
        }]
      end
    end

    context 'with supplement (525$a)' do
      let(:marc_hash) do
        {
          'fields' => [
            {
              '525' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Has numerous supplements.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Has numerous supplements.'
        }]
      end
    end

    context 'with study program information (526$abcdiz) omitting $x' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '526' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Accelerated Reader AR'
                  },
                  {
                    'b' => 'Upper Grades'
                  },
                  {
                    'c' => '6.4'
                  },
                  {
                    'd' => '7.0'
                  },
                  {
                    'x' => 'This item used for a special parent\'s viewing.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Accelerated Reader AR Upper Grades 6.4 7.0'
        }]
      end
    end

    context 'with additional physical form (530$abcdu3)' do
      # See in00000144356
      let(:marc_hash) do
        {
          'fields' => [
            {
              '530' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Also available online to Stanford-affiliated users'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'additional physical form',
          value: 'Also available online to Stanford-affiliated users'
        }]
      end
    end

    context 'with accessibility (532$a3)' do
      # See a14354567
      let(:marc_hash) do
        {
          'fields' => [
            {
              '532' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Closed captioning in English'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Closed captioning in English'
        }]
      end
    end

    context 'with reproduction (533$abcdefmny3)' do
      # See a5461096
      let(:marc_hash) do
        {
          'fields' => [
            {
              '533' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Microfilm.'
                  },
                  {
                    'b' => 'Ann Arbor, Mich. :'
                  },
                  {
                    'b' => 'University Microfilms,'
                  },
                  {
                    'd' => '1970.'
                  },
                  {
                    'e' => '1 microfilm reel ; 35 mm.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'reproduction',
          value: 'Microfilm. Ann Arbor, Mich. : University Microfilms, 1970. 1 microfilm reel ; 35 mm.'
        }]
      end
    end

    context 'with original version (534$abcefklmnoptxz3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '534' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'p' => 'Reproduction of:'
                  },
                  {
                    't' => 'Femme nue en plein air,'
                  },
                  {
                    'c' => '1876.'
                  },
                  {
                    'e' => '1 art original : oil, col. ; 79 x 64 cm.'
                  },
                  {
                    'l' => 'In Louvre Museum, Paris.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Reproduction of: Femme nue en plein air, 1876. 1 art original : oil, col. ; 79 x 64 cm. In Louvre Museum, Paris.'
        }]
      end
    end

    context 'with location of originals/duplicates (535$abcdg3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '535' => {
                'ind1' => '2',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'German notebook'
                  },
                  {
                    'a' => 'Yale University Library, Department of Manuscripts and Archives;'
                  },
                  {
                    'b' => 'Box 1603A Yale Station, New Haven, CT 06520;'
                  },
                  {
                    'c' => 'USA;'
                  },
                  {
                    'd' => '203-436-4564'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'original location',
          value: 'German notebook Yale University Library, Department of Manuscripts and Archives; Box 1603A Yale Station, New Haven, CT 06520; USA; 203-436-4564'
        }]
      end
    end

    context 'with funding information (536$abcdefgh)' do
      # See a6631609
      let(:marc_hash) do
        {
          'fields' => [
            {
              '536' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Support provided by the Alfred P. Sloan Foundation.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'funding',
          value: 'Support provided by the Alfred P. Sloan Foundation.'
        }]
      end
    end

    context 'with system details (538$a)' do
      # See a14655722
      let(:marc_hash) do
        {
          'fields' => [
            {
              '538' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Disc characteristics: DVD-R'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'system details',
          value: 'Disc characteristics: DVD-R'
        }]
      end
    end

    context 'with terms governing use and reproduction (540$abcdfgqu3)' do
      # See a14394621
      let(:marc_hash) do
        {
          'fields' => [
            {
              '540' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'For the oral history interview of Pardais, © Stanford University. All Rights Reserved.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'use and reproduction',
          value: 'For the oral history interview of Pardais, © Stanford University. All Rights Reserved.'
        }]
      end
    end

    context 'with immediate source of acquisition (541$abcdefhno3 ind1 not 0)' do
      # See a14394621
      let(:marc_hash) do
        {
          'fields' => [
            {
              '541' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'c' => 'Gift,'
                  },
                  {
                    'd' => '2022.'
                  },
                  {
                    'e' => 'Accession 2022-369.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'acquisition',
          value: 'Gift, 2022. Accession 2022-369.'
        }]
      end
    end

    context 'with immediate source of acquisition (541$abcdefhno3 ind1=0)' do
      # See a14394621 - should not be mapped
      let(:marc_hash) do
        {
          'fields' => [
            {
              '541' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'c' => 'Gift,'
                  },
                  {
                    'd' => '2022.'
                  },
                  {
                    'e' => 'Accession 2022-369.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns empty' do
        expect(build).to eq []
      end
    end

    context 'with information relating to copyright status (542$abcdefghijklmnopqrsu3) - variant 1' do
      # Based on a11993949
      let(:marc_hash) do
        {
          'fields' => [
            {
              '542' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Created by anonymous.'
                  },
                  {
                    'l' => 'Public domain.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'copyright',
          value: 'Created by anonymous. Public domain.'
        }]
      end
    end

    context 'with information relating to copyright status (542$abcdefghijklmnopqrsu3) - variant 2' do
      # See a13180303
      let(:marc_hash) do
        {
          'fields' => [
            {
              '542' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'f' => '© JICA et IGN'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'copyright',
          value: '© JICA et IGN'
        }]
      end
    end

    context 'with location of other archival materials (544$abcden3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '544' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'd' => 'Baptismal records;'
                  },
                  {
                    'a' => 'St. Casimir\'s Parish;'
                  },
                  {
                    'a' => 'Milwaukee, Wisc.'
                  },
                  {
                    'c' => 'USA.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Baptismal records; St. Casimir\'s Parish; Milwaukee, Wisc. USA.'
        }]
      end
    end

    context 'with biographical or historical data (545$abu)' do
      # See a13886995
      let(:marc_hash) do
        {
          'fields' => [
            {
              '545' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => '"Naonori Kohira has worked around the world on various projects, and his media producing work ' \
                           'is an extension of his photojournalistic style. His eye for detail and keen perception allow him to capure the truly important moments of your day."' \
                           '--Kohira Parsons Project website'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'biographical/historical',
          value: '"Naonori Kohira has worked around the world on various projects, and his media producing work ' \
                 'is an extension of his photojournalistic style. His eye for detail and keen perception allow him to capure the truly important moments of your day."' \
                 '--Kohira Parsons Project website'
        }]
      end
    end

    context 'with language (546$ab3) - variant 1' do
      # See a12365535
      let(:marc_hash) do
        {
          'fields' => [
            {
              '546' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Sung in French, German, and Italian.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'language',
          value: 'Sung in French, German, and Italian.'
        }]
      end
    end

    context 'with language (546$ab3) - variant 2' do
      # See a14185492
      let(:marc_hash) do
        {
          'fields' => [
            {
              '546' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'b' => 'Staff notation'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'language',
          value: 'Staff notation'
        }]
      end
    end

    context 'with former title complexity (547$a)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '547' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Edition varies: 1916, New York edition.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Edition varies: 1916, New York edition.'
        }]
      end
    end

    context 'with issuing body (550$a)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '550' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Vols. for 1921-1927 published under the auspices of the British Institute of International Affairs.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Vols. for 1921-1927 published under the auspices of the British Institute of International Affairs.'
        }]
      end
    end

    context 'with entity and attribute information (552$abcdefghijklmnopuz)' do
      # See a13691260
      let(:marc_hash) do
        {
          'fields' => [
            {
              '552' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Eight sets of entity and attribute information provided on CD-ROM under [CD-ROM drive]:/arabian/metadata/html/metadata.htm'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Eight sets of entity and attribute information provided on CD-ROM under [CD-ROM drive]:/arabian/metadata/html/metadata.htm'
        }]
      end
    end

    context 'with cumulative index/finding aids (555$abcdu3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '555' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Claims settled under Treaty of Washington, May 8, 1871.'
                  },
                  {
                    'a' => 'Preliminary inventory prepared in 1962;'
                  },
                  {
                    'b' => 'Available in NARS central search room;'
                  },
                  {
                    'b' => 'NARS Publications Sales Branch;'
                  },
                  {
                    'd' => 'Ulibarri, George S.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Claims settled under Treaty of Washington, May 8, 1871. Preliminary inventory prepared in 1962; Available in NARS central search room; NARS Publications Sales Branch; Ulibarri, George S.'
        }]
      end
    end

    context 'with information about documentation (556$az)' do
      let(:marc_hash) do
        {
          'fields' => [
            {
              '556' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'BASIC reference. 3rd ed. Boca Raton, Fl. : IBM, c1984. (Personal computer hardware reference library); 6361132.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'BASIC reference. 3rd ed. Boca Raton, Fl. : IBM, c1984. (Personal computer hardware reference library); 6361132.'
        }]
      end
    end

    context 'with ownership and custodial history (561$au3 ind1 not 0)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '561' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Family correspondence'
                  },
                  {
                    'a' => 'Collated: 1845-1847.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'ownership',
          value: 'Family correspondence Collated: 1845-1847.'
        }]
      end
    end

    context 'with ownership and custodial history (561$au3 ind1=0)' do
      # LC example - should not be mapped
      let(:marc_hash) do
        {
          'fields' => [
            {
              '561' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Family correspondence'
                  },
                  {
                    'a' => 'Collated: 1845-1847.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns empty' do
        expect(build).to eq []
      end
    end

    context 'with copy and version identification (562$abcde3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '562' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Deacidified copy'
                  },
                  {
                    'a' => 'With Braun\'s annotations by hand;'
                  },
                  {
                    'b' => 'Includes personal library seal embossed.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'version identification',
          value: 'Deacidified copy With Braun\'s annotations by hand; Includes personal library seal embossed.'
        }]
      end
    end

    context 'with binding information (563$au3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '563' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Late 16th century blind-tooled centrepiece binding, dark brown calf.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'binding',
          value: 'Late 16th century blind-tooled centrepiece binding, dark brown calf.'
        }]
      end
    end

    context 'with case file characteristics (565$abcde3)' do
      # See a1738322
      let(:marc_hash) do
        {
          'fields' => [
            {
              '565' => {
                'ind1' => '8',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'File size unknown.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'File size unknown.'
        }]
      end
    end

    context 'with methodology (567$ab)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '567' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Continuous, deterministic, predictive.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Continuous, deterministic, predictive.'
        }]
      end
    end

    context 'with linking entry complexity (580$a)' do
      # See in00000144356
      let(:marc_hash) do
        {
          'fields' => [
            {
              '580' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Continues a loose-leaf publication with the same title'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Continues a loose-leaf publication with the same title'
        }]
      end
    end

    context 'with publications about described materials (581$az3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '581' => {
                'ind1' => '8',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Inventory of American Sculpture: photocopy. 1982.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'publications',
          value: 'Inventory of American Sculpture: photocopy. 1982.'
        }]
      end
    end

    context 'with action note (583$abcdefhijklnouz3 ind1 not 0)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '583' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => '8 record center cartons'
                  },
                  {
                    'n' => '8'
                  },
                  {
                    'o' => 'cu. ft.'
                  },
                  {
                    'a' => 'accession'
                  },
                  {
                    'b' => '82-14'
                  },
                  {
                    'c' => '19820606'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'action',
          value: '8 record center cartons 8 cu. ft. accession 82-14 19820606'
        }]
      end
    end

    context 'with action note (583$abcdefhijklnouz3 ind1=0)' do
      # LC example - should not be mapped
      let(:marc_hash) do
        {
          'fields' => [
            {
              '583' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => '8 record center cartons'
                  },
                  {
                    'n' => '8'
                  },
                  {
                    'o' => 'cu. ft.'
                  },
                  {
                    'a' => 'accession'
                  },
                  {
                    'b' => '82-14'
                  },
                  {
                    'c' => '19820606'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns empty' do
        expect(build).to eq []
      end
    end

    context 'with accumulation and frequency of use (584$ab3)' do
      let(:marc_hash) do
        {
          'fields' => [
            {
              '584' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'General subject files'
                  },
                  {
                    'a' => '45 cu. ft. average annual accumulation 1970-1979.'
                  },
                  {
                    'a' => 'Current average monthly accumulation is 2 cu. ft.'
                  },
                  {
                    'b' => 'Total reference requests for 1984: 179'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'General subject files 45 cu. ft. average annual accumulation 1970-1979. Current average monthly accumulation is 2 cu. ft. Total reference requests for 1984: 179'
        }]
      end
    end

    context 'with exhibitions note (585$a3)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            {
              '585' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => 'Color lithographs'
                  },
                  {
                    'a' => 'Exhibited: "Le Brun à Versailles," sponsored by the Cabinet des dessins, Musée du Louvre, 1985-1986.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'exhibitions',
          value: 'Color lithographs Exhibited: "Le Brun à Versailles," sponsored by the Cabinet des dessins, Musée du Louvre, 1985-1986.'
        }]
      end
    end

    context 'with awards note (586$a3)' do
      # See a14354567
      let(:marc_hash) do
        {
          'fields' => [
            {
              '586' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Sundance Film Festival U.S. Documentary Directing Award, 2022'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Sundance Film Festival U.S. Documentary Directing Award, 2022'
        }]
      end
    end

    context 'with source of description (588$a)' do
      # See a14349595
      let(:marc_hash) do
        {
          'fields' => [
            {
              '588' => {
                'ind1' => '0',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'MARC derived from Rigler Deutsch Project OCLC id: 82298678'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'MARC derived from Rigler Deutsch Project OCLC id: 82298678'
        }]
      end
    end

    context 'with local note (590$a)' do
      # See a10760602
      let(:marc_hash) do
        {
          'fields' => [
            {
              '590' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Archive of Recorded Sound copy with pencilled note on reverse of leader: "26 Koob"[?]'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          value: 'Archive of Recorded Sound copy with pencilled note on reverse of leader: "26 Koob"[?]'
        }]
      end
    end

    context 'with local collection note (795$a)' do
      # See a11351916
      let(:marc_hash) do
        {
          'fields' => [
            {
              '795' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Denis Condon collection of reproducing pianos and rolls'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [{
          type: 'provenance',
          value: 'Denis Condon collection of reproducing pianos and rolls'
        }]
      end
    end

    context 'with note in multiple scripts (500/880)' do
      # See a13355277
      let(:marc_hash) do
        {
          'fields' => [
            {
              '500' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '880-01'
                  },
                  {
                    'a' => 'At head of title: T͡Sentr izuchenii͡a krizisnogo obshchestva. Laboratorii͡a issledovaniĭ mirovogo pori͡adka i novogo regionalizma Nat͡sionalʹnogo issledovatelʹskogo universiteta "Vysshai͡a shkola ėkonomiki."'
                  }
                ]
              }
            },
            {
              '880' => {
                'ind1' => ' ',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '500-01'
                  },
                  {
                    'a' => 'At head of title: Центр изучения кризисного общества. Лаборатория исследований мирового порядка и нового регионализма Национального исследовательского университета "Высшая школа экономики."'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns notes' do
        expect(build).to eq [
          {
            value: 'At head of title: T͡Sentr izuchenii͡a krizisnogo obshchestva. Laboratorii͡a issledovaniĭ mirovogo pori͡adka i novogo regionalizma Nat͡sionalʹnogo issledovatelʹskogo universiteta "Vysshai͡a shkola ėkonomiki."'
          },
          {
            value: 'At head of title: Центр изучения кризисного общества. Лаборатория исследований мирового порядка и нового регионализма Национального исследовательского университета "Высшая школа экономики."'
          }
        ]
      end
    end
  end
end
