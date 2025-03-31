# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::DescriptiveMetadataIndexer do
  subject(:indexer) { described_class.new(cocina:) }

  let(:bare_druid) { 'qy781dy0220' }
  let(:druid) { "druid:#{bare_druid}" }
  let(:titles) { [{ value: 'override me' }] }
  let(:doc) { indexer.to_solr }
  let(:description) do
    {
      title: titles,
      purl: "https://purl.stanford.edu/#{bare_druid}"
    }
  end
  let(:cocina) { build(:dro, id: druid).new(description:) }

  describe 'title mappings from Cocina to Solr' do
    # 'main_title_tenim' => main_title, # for searching; 2 more field types are copyFields in solr schema.xml
    # (to improve search results)
    # 'full_title_tenim' => full_title, # for searching; 1 more field type is copyField in solr schema.xml
    # 'additional_titles_tenim' => additional_titles, # for searching; 1 more field type is copyField in solr schema.xml
    # 'display_title_ss' => display_title, # for display in Argo

    context 'with multiple typed and untyped simple title values, one status primary' do
      let(:titles) do
        [
          {
            value: 'Not Primary'
          },
          {
            value: 'Primary Title',
            type: 'translated',
            status: 'primary'
          }
        ]
      end

      it 'main_title_tenim is value with status primary' do
        expect(doc['main_title_tenim']).to eq ['Primary Title']
      end

      it 'full_title_tenim is value with status primary' do
        expect(doc['full_title_tenim']).to eq ['Primary Title']
      end

      it 'additional_titles_tenim is value(s) without status primary' do
        expect(doc['additional_titles_tenim']).to eq ['Not Primary']
      end

      it 'display_title_ss is value with status primary' do
        expect(doc['display_title_ss']).to eq 'Primary Title'
      end
    end

    context 'with multiple typed titles, none status primary' do
      # Select first
      let(:titles) do
        [
          {
            value: 'First',
            type: 'translated'
          },
          {
            value: 'Second',
            type: 'alternative'
          },
          {
            value: 'Third',
            type: 'transliterated'
          }
        ]
      end

      it 'main_title_tenim is first value' do
        expect(doc['main_title_tenim']).to eq ['First']
      end

      it 'full_title_tenim is first value' do
        expect(doc['full_title_tenim']).to eq ['First']
      end

      it 'additional_titles_tenim is non-first values' do
        expect(doc['additional_titles_tenim']).to eq %w[Second Third]
      end

      it 'display_title_ss is first value' do
        expect(doc['display_title_ss']).to eq 'First'
      end
    end

    context 'with space/punctuation/space ending simple value' do
      let(:titles) do
        [
          { value: 'Title /' }
        ]
      end

      # strip one or more instances of .,;:/\ plus whitespace at beginning or end of string

      it 'main_title_tenim is value without trailing punctuation or spaces' do
        expect(doc['main_title_tenim']).to eq ['Title']
      end

      it 'full_title_tenim is value without trailing punctuation or spaces' do
        expect(doc['full_title_tenim']).to eq ['Title']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is value without trailing punctuation or spaces' do
        expect(doc['display_title_ss']).to eq 'Title'
      end
    end

    context 'with structuredValue with all parts in common order' do
      let(:titles) do
        [
          {
            structuredValue: [
              {
                value: 'A',
                type: 'nonsorting characters'
              },
              {
                value: 'title',
                type: 'main title'
              },
              {
                value: 'a subtitle',
                type: 'subtitle'
              },
              {
                value: 'Vol. 1',
                type: 'part number'
              },
              {
                value: 'Supplement',
                type: 'part name'
              }
            ]
          }
        ]
      end

      it 'main_title_tenim is main title and nonsorting character' do
        expect(doc['main_title_tenim']).to eq ['A title']
      end

      it 'full_title_tenim is rebuilt structuredValue withOUT additional punctuation' do
        expect(doc['full_title_tenim']).to eq ['A title a subtitle Vol. 1 Supplement']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is rebuilt structuredValue with punctuation' do
        expect(doc['display_title_ss']).to eq 'A title : a subtitle. Vol. 1, Supplement'
      end
    end

    context 'with structuredValue with parts in uncommon order' do
      # uses given field order; based on ckey 9803970
      let(:titles) do
        [
          {
            structuredValue: [
              {
                value: 'The',
                type: 'nonsorting characters'
              },
              {
                value: 'title',
                type: 'main title'
              },
              {
                value: 'Vol. 1',
                type: 'part number'
              },
              {
                value: 'Supplement',
                type: 'part name'
              },
              {
                value: 'a subtitle',
                type: 'subtitle'
              }
            ]
          }
        ]
      end

      it 'main_title_tenim is main title and nonsorting chars' do
        expect(doc['main_title_tenim']).to eq ['The title']
      end

      it 'full_title_tenim is rebuilt structured value withOUT additional punctuation' do
        expect(doc['full_title_tenim']).to eq ['The title Vol. 1 Supplement a subtitle']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is rebuilt structured value with punctuation' do
        expect(doc['display_title_ss']).to eq 'The title. Vol. 1, Supplement : a subtitle'
      end
    end

    context 'with structuredValue with nonsorting character count' do
      let(:titles) do
        [
          {
            structuredValue: [
              {
                value: "L'",
                type: 'nonsorting characters'
              },
              {
                value: 'autre title',
                type: 'main title'
              }
            ],
            note: [
              {
                value: '2',
                type: 'nonsorting character count'
              }
            ]
          }
        ]
      end

      # it does not force a space separator
      it 'main_title_tenim includes nonsorting chars without extra space' do
        expect(doc['main_title_tenim']).to eq ['L\'autre title']
      end

      it 'full_title_tenim includes nonsorting chars without extra space' do
        expect(doc['full_title_tenim']).to eq ['L\'autre title']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      # it does not force a space separator
      it 'display_title_ss includes nonsorting chars without extra space' do
        expect(doc['display_title_ss']).to eq 'L\'autre title'
      end
    end

    context 'with structuredValue with nonsorting characters not first' do
      let(:titles) do
        [
          {
            structuredValue: [
              {
                value: 'Series 1',
                type: 'part number'
              },
              {
                value: 'A',
                type: 'nonsorting characters'
              },
              {
                value: 'Title',
                type: 'main title'
              }
            ]
          }
        ]
      end

      it 'main_title_tenim is main title with nonsorting characters' do
        expect(doc['main_title_tenim']).to eq ['A Title']
      end

      it 'full_title_tenim is reconstructed value in occurrence order withOUT punctuation' do
        expect(doc['full_title_tenim']).to eq ['Series 1 A Title']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is reconstructed value in occurrence order with punctuation added' do
        expect(doc['display_title_ss']).to eq 'Series 1. A Title'
      end
    end

    context 'with structuredValue for uniform title' do
      let(:titles) do
        [
          {
            value: 'Title',
            type: 'uniform',
            note: [
              {
                value: 'Author, An',
                type: 'associated name'
              }
            ]
          }
        ]
      end
      let(:contributors) do
        [
          { name: [{ value: 'Author, An' }] }
        ]
      end
      let(:description) do
        {
          title: titles,
          contributor: contributors,
          purl: "https://purl.stanford.edu/#{bare_druid}"
        }
      end

      # Omit author name when uniform title is preferred title for display

      it 'main_title_tenim is value of the only title without associated name note' do
        expect(doc['main_title_tenim']).to eq ['Title']
      end

      it 'full_title_tenim is value of the only title without associated name note' do
        expect(doc['full_title_tenim']).to eq ['Title']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is value of the only title without associated name note' do
        expect(doc['display_title_ss']).to eq 'Title'
      end
    end

    context 'with structuredValue containing punctuation/space in individual values' do
      let(:titles) do
        [
          {
            structuredValue: [
              {
                value: 'Title.',
                type: 'main title'
              },
              {
                value: ':subtitle /',
                type: 'subtitle'
              }
            ]
          }
        ]
      end

      # strip one or more instances of .,;:/\ plus whitespace at beginning or end of string

      it 'main_title_tenim is main title only' do
        expect(doc['main_title_tenim']).to eq ['Title']
      end

      it 'full_title_tenim is reconstructed value withOUT punctuation' do
        expect(doc['full_title_tenim']).to eq ['Title subtitle']
      end

      it 'additional_titles_tenim is value(s) is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is reconstructed value with adjusted punctuation' do
        expect(doc['display_title_ss']).to eq 'Title : subtitle'
      end
    end

    context 'with parallelValue with primary on (whole) parallelValue' do
      let(:titles) do
        [
          {
            parallelValue: [
              {
                value: 'Title 1'
              },
              {
                value: 'Title 2'
              }
            ],
            status: 'primary'
          }
        ]
      end

      it 'main_title_tenim is both parallel values' do
        expect(doc['main_title_tenim']).to eq ['Title 1', 'Title 2']
      end

      it 'full_title_tenim is both parallel values' do
        expect(doc['full_title_tenim']).to eq ['Title 1', 'Title 2']
      end

      it 'additional_titles_tenim is nil' do
        expect(doc['additional_titles_tenim']).to be_nil
      end

      it 'display_title_ss is first parallel value' do
        expect(doc['display_title_ss']).to eq 'Title 1'
      end
    end
  end
end
