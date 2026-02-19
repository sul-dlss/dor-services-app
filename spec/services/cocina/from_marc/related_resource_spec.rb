# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::RelatedResource do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:require_title) { true }
    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with in series (490$alvx3)' do
      # based on a5643572
      let(:marc_hash) do
        {
          'fields' => [
            {
              '490' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '3' => '<1981->:'
                  },
                  {
                    'a' => 'Le Masque ;'
                  },
                  {
                    'v' => '567'
                  },
                  {
                    'l' => '(AB123)'
                  },
                  {
                    'x' => '1234-5678'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns in series' do
        expect(build).to eq [{ type: 'in series', title: '<1981->: Le Masque ; 567 (AB123) 1234-5678' }]
      end
    end

    context 'with has part with person contributor (700 ind2=2 with $t)' do
      # constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '700' => {
                'ind1' => '1',
                'ind2' => '2',
                'subfields' => [
                  {
                    'i' => 'Relationship information:'
                  },
                  {
                    'a' => 'Personal name,'
                  },
                  {
                    'b' => 'numeration,'
                  },
                  {
                    'c' => 'titles associated with name,'
                  },
                  {
                    'd' => 'dates associated with name,'
                  },
                  {
                    'j' => 'attribution qualifier'
                  },
                  {
                    'q' => '(fuller form of name),'
                  },
                  {
                    'e' => 'author.'
                  },
                  {
                    '4' => 'aut'
                  },
                  {
                    'u' => '(affiliation)'
                  },
                  {
                    '1' => 'RWO URI'
                  },
                  {
                    't' => 'Title of a work.'
                  },
                  {
                    'f' => 'Date of a work.'
                  },
                  {
                    'g' => 'Miscellaneous information.'
                  },
                  {
                    'k' => 'Form subheading.'
                  },
                  {
                    'l' => 'Language.'
                  },
                  {
                    'm' => 'Medium of performance,'
                  },
                  {
                    'n' => 'number of part,'
                  },
                  {
                    'p' => 'name of part,'
                  },
                  {
                    'o' => 'arranged statement.'
                  },
                  {
                    'r' => 'Key for music.'
                  },
                  {
                    's' => 'Version.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns has part with person contributor' do
        expect(build).to eq [{
          type: 'has part',
          displayLabel: 'Relationship information:',
          title: [{ value: 'Title of a work. Date of a work. Miscellaneous information. Form subheading. Language. Medium of performance, number of part, name of part, arranged statement. Key for music. Version.' }],
          contributor: [
            {
              type: 'person',
              name: [{ value: 'Personal name, numeration, titles associated with name, dates associated with name, attribution qualifier (fuller form of name)' }],
              affiliation: [{ value: '(affiliation)' }],
              role: [{ value: 'author' }],
              identifier: [{ uri: 'RWO URI' }]
            }
          ]
        }]
      end
    end

    context 'with related title with person contributor (700 ind2 not 2)' do
      # a5643572
      let(:marc_hash) do
        {
          'fields' => [
            {
              '700' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'i' => 'Translation of (expression):'
                  },
                  {
                    'a' => 'Sayers, Dorothy L.'
                  },
                  {
                    'q' => '(Dorothy Leigh),'
                  },
                  {
                    'd' => '1893-1957'
                  },
                  {
                    't' => 'Nine tailors.'
                  },
                  {
                    '0' => '(SIRSI)100978'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns related to with person contributor' do
        expect(build).to eq [{
          type: 'related to',
          displayLabel: 'Translation of (expression):',
          title: [{ value: 'Nine tailors.' }],
          contributor: [
            {
              type: 'person',
              name: [{ value: 'Sayers, Dorothy L. (Dorothy Leigh), 1893-1957' }]
            }
          ]
        }]
      end
    end

    context 'with related title with person contributor (700 ind2 not 2, constructed)' do
      # constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '700' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'i' => 'Relationship information:'
                  },
                  {
                    'a' => 'Personal name,'
                  },
                  {
                    'b' => 'numeration,'
                  },
                  {
                    'c' => 'titles associated with name,'
                  },
                  {
                    'd' => 'dates associated with name,'
                  },
                  {
                    'j' => 'attribution qualifier'
                  },
                  {
                    'q' => '(fuller form of name),'
                  },
                  {
                    'e' => 'author.'
                  },
                  {
                    '4' => 'aut'
                  },
                  {
                    'u' => '(affiliation)'
                  },
                  {
                    '1' => 'RWO URI'
                  },
                  {
                    't' => 'Title of a work.'
                  },
                  {
                    'f' => 'Date of a work.'
                  },
                  {
                    'g' => 'Miscellaneous information.'
                  },
                  {
                    'k' => 'Form subheading.'
                  },
                  {
                    'l' => 'Language.'
                  },
                  {
                    'm' => 'Medium of performance,'
                  },
                  {
                    'n' => 'number of part,'
                  },
                  {
                    'p' => 'name of part,'
                  },
                  {
                    'o' => 'arranged statement.'
                  },
                  {
                    'r' => 'Key for music.'
                  },
                  {
                    's' => 'Version.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns related to with person contributor' do
        expect(build).to eq [{
          type: 'related to',
          displayLabel: 'Relationship information:',
          title: [{ value: 'Title of a work. Date of a work. Miscellaneous information. Form subheading. Language. Medium of performance, number of part, name of part, arranged statement. Key for music. Version.' }],
          contributor: [
            {
              type: 'person',
              name: [{ value: 'Personal name, numeration, titles associated with name, dates associated with name, attribution qualifier (fuller form of name)' }],
              affiliation: [{ value: '(affiliation)' }],
              role: [{ value: 'author' }],
              identifier: [{ uri: 'RWO URI' }]
            }
          ]
        }]
      end
    end

    context 'with related title with family contributor (700 ind1=3)' do
      # constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '700' => {
                'ind1' => '3',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'a' => 'Elliott family.'
                  },
                  {
                    't' => 'Book of hours.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns related to with family contributor' do
        expect(build).to eq [{
          type: 'related to',
          title: [{ value: 'Book of hours.' }],
          contributor: [
            {
              type: 'family',
              name: [{ value: 'Elliott family.' }]
            }
          ]
        }]
      end
    end

    context 'with has part with organization contributor (710 ind2=2)' do
      # constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '710' => {
                'ind1' => '1',
                'ind2' => '2',
                'subfields' => [
                  {
                    'i' => 'Relationship information:'
                  },
                  {
                    'a' => 'Corporate name,'
                  },
                  {
                    'b' => 'subordinate unit,'
                  },
                  {
                    'c' => 'location of meeting,'
                  },
                  {
                    'd' => 'date of meeting,'
                  },
                  {
                    'e' => 'author.'
                  },
                  {
                    '4' => 'aut'
                  },
                  {
                    '1' => 'RWO URI'
                  },
                  {
                    't' => 'Title of a work.'
                  },
                  {
                    'f' => 'Date of a work.'
                  },
                  {
                    'g' => 'Miscellaneous information.'
                  },
                  {
                    'k' => 'Form subheading.'
                  },
                  {
                    'l' => 'Language.'
                  },
                  {
                    'm' => 'Medium of performance,'
                  },
                  {
                    'n' => 'number of part,'
                  },
                  {
                    'p' => 'name of part,'
                  },
                  {
                    'o' => 'arranged statement.'
                  },
                  {
                    'r' => 'Key for music.'
                  },
                  {
                    's' => 'Version.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns has part with organization contributor' do
        expect(build).to eq [{
          type: 'has part',
          displayLabel: 'Relationship information:',
          title: [{ value: 'Title of a work. Date of a work. Miscellaneous information. Form subheading. Language. Medium of performance, number of part, name of part, arranged statement. Key for music. Version.' }],
          contributor: [
            {
              type: 'organization',
              name: [{ value: 'Corporate name, subordinate unit, location of meeting, date of meeting' }],
              role: [{ value: 'author' }],
              identifier: [{ uri: 'RWO URI' }]
            }
          ]
        }]
      end
    end

    context 'with related title with event contributor (711 ind2=2)' do
      # constructed
      let(:marc_hash) do
        {
          'fields' => [
            {
              '711' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    'i' => 'Relationship information:'
                  },
                  {
                    'a' => 'Meeting name,'
                  },
                  {
                    'c' => 'location of meeting,'
                  },
                  {
                    'd' => 'date of meeting,'
                  },
                  {
                    'e' => 'subordinate unit,'
                  },
                  {
                    'q' => 'part of meeting name,'
                  },
                  {
                    'u' => '(affiliation)'
                  },
                  {
                    'j' => 'author.'
                  },
                  {
                    '4' => 'aut'
                  },
                  {
                    '1' => 'RWO URI'
                  },
                  {
                    't' => 'Title of a work.'
                  },
                  {
                    'f' => 'Date of a work.'
                  },
                  {
                    'g' => 'Miscellaneous information.'
                  },
                  {
                    'k' => 'Form subheading.'
                  },
                  {
                    'l' => 'Language.'
                  },
                  {
                    'n' => 'Number of part,'
                  },
                  {
                    'p' => 'name of part.'
                  },
                  {
                    's' => 'Version.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns related to with event contributor' do
        expect(build).to eq [{
          type: 'related to',
          displayLabel: 'Relationship information:',
          title: [{ value: 'Title of a work. Date of a work. Miscellaneous information. Form subheading. Language. Number of part, name of part. Version.' }],
          contributor: [
            {
              type: 'organization',
              name: [{ value: 'Meeting name, location of meeting, date of meeting, subordinate unit, part of meeting name' }],
              affiliation: [{ value: '(affiliation)' }],
              role: [{ value: 'author' }],
              identifier: [{ uri: 'RWO URI' }]
            }
          ]
        }]
      end
    end

    context 'with related title with multiple scripts (700/880)' do
      # a6669233
      let(:marc_hash) do
        {
          'fields' => [
            {
              '700' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '880-01'
                  },
                  {
                    'a' => 'Asaka, Tanpaku,'
                  },
                  {
                    'd' => '1656-1737.'
                  },
                  {
                    't' => 'Gikō gyōjitsu.'
                  },
                  {
                    '0' => '(SIRSI)2279434'
                  }
                ]
              }
            },
            {
              '880' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '700-07'
                  },
                  {
                    'a' => '安積澹泊,'
                  },
                  {
                    'd' => '1656-1737.'
                  },
                  {
                    't' => '義公業實.'
                  }
                ]
              }
            },
            {
              '700' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '880-02'
                  },
                  {
                    'a' => 'Asaka, Tanpaku,'
                  },
                  {
                    'd' => '1656-1737.'
                  },
                  {
                    't' => 'Seizan iji.'
                  },
                  {
                    '0' => '(SIRSI)2279434'
                  }
                ]
              }
            },
            {
              '880' => {
                'ind1' => '1',
                'ind2' => ' ',
                'subfields' => [
                  {
                    '6' => '700-08'
                  },
                  {
                    'a' => '安積澹泊,'
                  },
                  {
                    'd' => '1656-1737.'
                  },
                  {
                    't' => 'Seizan iji.'
                  }
                ]
              }
            }
          ]
        }
      end

      it 'returns multiple related resources with different scripts' do
        expect(build).to eq [
          {
            type: 'related to',
            title: [{ value: 'Gikō gyōjitsu.' }],
            contributor: [
              {
                type: 'person',
                name: [{ value: 'Asaka, Tanpaku, 1656-1737.' }]
              }
            ]
          },
          {
            type: 'related to',
            title: [{ value: '義公業實.' }],
            contributor: [
              {
                type: 'person',
                name: [{ value: '安積澹泊, 1656-1737.' }]
              }
            ]
          },
          {
            type: 'related to',
            title: [{ value: 'Seizan iji.' }],
            contributor: [
              {
                type: 'person',
                name: [{ value: 'Asaka, Tanpaku, 1656-1737.' }]
              }
            ]
          },
          {
            type: 'related to',
            title: [{ value: 'Seizan iji.' }],
            contributor: [
              {
                type: 'person',
                name: [{ value: '安積澹泊, 1656-1737.' }]
              }
            ]
          }
        ]
      end
    end
  end
end
