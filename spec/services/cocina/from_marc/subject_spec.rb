# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromMarc::Subject do
  describe '.build' do
    subject(:build) do
      described_class.build(marc: marc)
    end

    let(:marc) { MARC::Record.new_from_hash(marc_hash) }

    context 'with an LCC subject (050$ab)' do
      # See a11655929
      let(:marc_hash) do
        {
          'fields' => [
            { '050' => {
              'ind1' => ' ', 'ind2' => '4',
              'subfields' => [
                { 'a' => 'G4332.C5K6 2016' },
                { 'b' => '.U5' }
              ]
            } }
          ]
        }
      end

      it 'returns LCC value' do
        expect(build).to eq [{ value: 'G4332.C5K6 2016.U5', type: 'classification', source: { code: 'lcc' } }]
      end
    end

    context 'with a SUDOC subject (086$a with ind1=0)' do
      # See a11655929
      let(:marc_hash) do
        {
          'fields' => [
            { '086' => {
              'ind1' => '0', 'ind2' => ' ',
              'subfields' => [
                { 'a' => 'A 13.36/2:C 64/2/2016' }
              ]
            } }
          ]
        }
      end

      it 'returns SUDOC value' do
        expect(build).to eq [{ value: 'A 13.36/2:C 64/2/2016', type: 'classification', source: { code: 'sudoc' } }]
      end
    end

    context 'with map coordinates (255$c)' do
      # See a11655929
      let(:marc_hash) do
        {
          'fields' => [
            { '255' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [
                { 'c' => '(W 111°58ʹ00ʺ--W 110°45ʹ00ʺ/N 35°36ʹ00ʺ--N 34°25ʹ00ʺ).' }
              ]
            } }
          ]
        }
      end

      it 'returns map coordinates value' do
        expect(build).to eq [{ value: '(W 111°58ʹ00ʺ--W 110°45ʹ00ʺ/N 35°36ʹ00ʺ--N 34°25ʹ00ʺ).',
                               type: 'map coordinates' }]
      end
    end

    context 'with uncontrolled topic (653$a with ind2=0)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Mann' }
              ]
            } }
          ]
        }
      end

      it 'returns topic value' do
        expect(build).to eq [{ value: 'Mann', type: 'topic' }]
      end
    end

    context 'with uncontrolled person (653$a with ind2=1)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '1',
              'subfields' => [
                { 'a' => 'Joyce' }
              ]
            } }
          ]
        }
      end

      it 'returns person value' do
        expect(build).to eq [{ value: 'Joyce', type: 'person' }]
      end
    end

    context 'with uncontrolled organization (653$a with ind2=2)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '2',
              'subfields' => [
                { 'a' => 'UNICEF' }
              ]
            } }
          ]
        }
      end

      it 'returns organization value' do
        expect(build).to eq [{ value: 'UNICEF', type: 'organization' }]
      end
    end

    context 'with uncontrolled event (653$a with ind2=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '3',
              'subfields' => [
                { 'a' => 'SIGGRAPH' }
              ]
            } }
          ]
        }
      end

      it 'returns event value' do
        expect(build).to eq [{ value: 'SIGGRAPH', type: 'event' }]
      end
    end

    context 'with uncontrolled chronological period (653$a with ind2=4)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '4',
              'subfields' => [
                { 'a' => 'Roaring Twenties' }
              ]
            } }
          ]
        }
      end

      it 'returns time value' do
        expect(build).to eq [{ value: 'Roaring Twenties', type: 'time' }]
      end
    end

    context 'with uncontrolled place (653$a with ind2=5)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '5',
              'subfields' => [
                { 'a' => 'Dublin' }
              ]
            } }
          ]
        }
      end

      it 'returns place value' do
        expect(build).to eq [{ value: 'Dublin', type: 'place' }]
      end
    end

    context 'with uncontrolled genre (653$a with ind2=6)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '6',
              'subfields' => [
                { 'a' => 'Hand colouring' }
              ]
            } }
          ]
        }
      end

      it 'returns form value' do
        expect(build).to eq [{ value: 'Hand colouring', type: 'genre' }]
      end
    end

    context 'with uncontrolled topics (653$a with ind2=blank and multiple subfields)' do
      # LC example
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [
                { 'a' => 'Man' },
                { 'a' => 'Eyes' },
                { 'a' => 'Diseases' }
              ]
            } }
          ]
        }
      end

      it 'returns multiple topic values' do
        expect(build).to eq [
          { value: 'Man', type: 'topic' },
          { value: 'Eyes', type: 'topic' },
          { value: 'Diseases', type: 'topic' }
        ]
      end
    end

    context 'with topic with subdivisions (650)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '650' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Topic 1.' },
                { 'b' => 'Topic 2.' },
                { 'c' => 'Location,' },
                { 'd' => 'Dates,' },
                { 'e' => 'Relator.' },
                { 'g' => 'Misc.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns topic with subdivisions and form' do
        expect(build).to eq [
          { value: 'Topic 1. Topic 2. Location, Dates, Relator. Misc.', type: 'topic' },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with person with subdivisions (600 without $t and ind1!=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '600' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Person name.' },
                { 'b' => 'Numeration.' },
                { 'c' => 'Titles.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Relator.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'j' => 'Attribution.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'm' => 'Medium of performance.' },
                { 'n' => 'Part number.' },
                { 'o' => 'Arranged.' },
                { 'p' => 'Part name.' },
                { 'q' => 'Fuller name.' },
                { 'r' => 'Key.' },
                { 's' => 'Version.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns person with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Person name. Numeration. Titles. Dates. Relator. Date. Misc. Medium. Attribution. Form. Language. Medium of performance. Part number. Arranged. Part name. Fuller name. Key. Version. Affiliation.', type: 'person'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with family with subdivisions (600 without $t and ind1=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '600' => {
              'ind1' => '3', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Family name.' },
                { 'b' => 'Numeration.' },
                { 'c' => 'Titles.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Relator.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'j' => 'Attribution.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'm' => 'Medium of performance.' },
                { 'n' => 'Part number.' },
                { 'o' => 'Arranged.' },
                { 'p' => 'Part name.' },
                { 'q' => 'Fuller name.' },
                { 'r' => 'Key.' },
                { 's' => 'Version.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns family with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Family name. Numeration. Titles. Dates. Relator. Date. Misc. Medium. Attribution. Form. Language. Medium of performance. Part number. Arranged. Part name. Fuller name. Key. Version. Affiliation.', type: 'family'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with organization with subdivisions (610 without $t)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '610' => {
              'ind1' => '2', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Organization name.' },
                { 'b' => 'Unit.' },
                { 'c' => 'Location.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Relator.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'm' => 'Medium of performance.' },
                { 'n' => 'Part number.' },
                { 'o' => 'Arranged.' },
                { 'p' => 'Part name.' },
                { 'r' => 'Key.' },
                { 's' => 'Version.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns organization with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Organization name. Unit. Location. Dates. Relator. Date. Misc. Medium. Form. Language. Medium of performance. Part number. Arranged. Part name. Key. Version. Affiliation.', type: 'organization'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with event with subdivisions (611 without $t)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '611' => {
              'ind1' => '2', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Event name.' },
                { 'c' => 'Location.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Unit.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'j' => 'Relator.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'n' => 'Part number.' },
                { 'p' => 'Part name.' },
                { 'q' => 'Fuller name.' },
                { 's' => 'Version.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns event with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Event name. Location. Dates. Unit. Date. Misc. Medium. Relator. Form. Language. Part number. Part name. Fuller name. Version. Affiliation.', type: 'event'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with title with person/family plus subdivisions (600 with $t)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '600' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Person name.' },
                { 'b' => 'Numeration.' },
                { 'c' => 'Titles.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Relator.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'j' => 'Attribution.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'm' => 'Medium of performance.' },
                { 'n' => 'Part number.' },
                { 'o' => 'Arranged.' },
                { 'p' => 'Part name.' },
                { 'q' => 'Fuller name.' },
                { 'r' => 'Key.' },
                { 's' => 'Version.' },
                { 't' => 'Title.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns title with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Person name. Numeration. Titles. Dates. Relator. Date. Misc. Medium. Attribution. Form. Language. Medium of performance. Part number. Arranged. Part name. Fuller name. Key. Version. Title. Affiliation.', type: 'title'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with title with organization plus subdivisions (610 with $t)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '610' => {
              'ind1' => '2', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Organization name.' },
                { 'b' => 'Unit.' },
                { 'c' => 'Location.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Relator.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'm' => 'Medium of performance.' },
                { 'n' => 'Part number.' },
                { 'o' => 'Arranged.' },
                { 'p' => 'Part name.' },
                { 'r' => 'Key.' },
                { 's' => 'Version.' },
                { 't' => 'Title.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns title with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Organization name. Unit. Location. Dates. Relator. Date. Misc. Medium. Form. Language. Medium of performance. Part number. Arranged. Part name. Key. Version. Title. Affiliation.', type: 'title'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with title with event plus subdivisions (611 with $t)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '611' => {
              'ind1' => '2', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Event name.' },
                { 'c' => 'Location.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Unit.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'j' => 'Relator.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'n' => 'Part number.' },
                { 'p' => 'Part name.' },
                { 'q' => 'Fuller name.' },
                { 's' => 'Version.' },
                { 't' => 'Title.' },
                { 'u' => 'Affiliation.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns title with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Event name. Location. Dates. Unit. Date. Misc. Medium. Relator. Form. Language. Part number. Part name. Fuller name. Version. Title. Affiliation.', type: 'title'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with title with subdivisions (630)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '630' => {
              'ind1' => '0', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Uniform title.' },
                { 'd' => 'Dates.' },
                { 'e' => 'Relator.' },
                { 'f' => 'Date.' },
                { 'g' => 'Misc.' },
                { 'h' => 'Medium.' },
                { 'k' => 'Form.' },
                { 'l' => 'Language.' },
                { 'm' => 'Medium of performance.' },
                { 'n' => 'Part number.' },
                { 'o' => 'Arranged.' },
                { 'p' => 'Part name.' },
                { 'r' => 'Key.' },
                { 's' => 'Version.' },
                { 't' => 'Title.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns title with subdivisions and form' do
        expect(build).to eq [
          {
            value: 'Uniform title. Dates. Relator. Date. Misc. Medium. Form. Language. Medium of performance. Part number. Arranged. Part name. Key. Version. Title.', type: 'title'
          },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with place with subdivisions (651)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '651' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Geographic name.' },
                { 'e' => 'Relator.' },
                { 'g' => 'Misc.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns place with subdivisions and form' do
        expect(build).to eq [
          { value: 'Geographic name. Relator. Misc.', type: 'place' },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with time with subdivisions (648)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '648' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { 'a' => 'Chronological term.' },
                { 'e' => 'Relator.' },
                { 'v' => 'Form' },
                { 'x' => 'Topic' },
                { 'y' => 'Time' },
                { 'z' => 'Place' }
              ]
            } }
          ]
        }
      end

      it 'returns time with subdivisions and form' do
        expect(build).to eq [
          { value: 'Chronological term. Relator.', type: 'time' },
          { value: 'Topic', type: 'topic' },
          { value: 'Time', type: 'time' },
          { value: 'Place', type: 'place' },
          { value: 'Form', type: 'genre' }
        ]
      end
    end

    context 'with person with multiple scripts (600/880)' do
      # See a12380830
      let(:marc_hash) do
        {
          'fields' => [
            { '600' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Park, Geun-Hye' },
                { 'x' => 'Impeachment.' },
                { '0' => '(SIRSI)2214113' }
              ]
            } },
            { '880' => {
              'ind1' => '1', 'ind2' => '4',
              'subfields' => [
                { '6' => '600-01' },
                { 'a' => '박 근혜' },
                { 'x' => 'Impeachment.' }
              ]
            } }
          ]
        }
      end

      it 'returns person with multiple scripts' do
        expect(build).to eq [
          { value: 'Park, Geun-Hye', type: 'person' },
          { value: 'Impeachment.', type: 'topic' },
          { value: '박 근혜', type: 'person' }
        ]
      end
    end

    context 'with title + person with multiple scripts (600 with $t/880)' do
      # See a8930023
      let(:marc_hash) do
        {
          'fields' => [
            { '600' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Long, Yingtai' },
                { 't' => 'Da jiang da hai 1949.' },
                { '0' => '(SIRSI)2184178' }
              ]
            } },
            { '880' => {
              'ind1' => '1', 'ind2' => '4',
              'subfields' => [
                { '6' => '600-01' },
                { 'a' => '龍應台.' },
                { 't' => '大江大海一九四九.' }
              ]
            } }
          ]
        }
      end

      it 'returns title with multiple scripts' do
        expect(build).to eq [
          { value: 'Long, Yingtai Da jiang da hai 1949.', type: 'title' },
          { value: '龍應台. 大江大海一九四九.', type: 'title' }
        ]
      end
    end

    context 'with organization with multiple scripts (610/880)' do
      # See a13783761
      let(:marc_hash) do
        {
          'fields' => [
            { '610' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Liaoning Sheng (China).' },
                { 'b' => 'Zi yi ju' },
                { 'x' => 'History' },
                { 'v' => 'Sources.' }
              ]
            } },
            { '880' => {
              'ind1' => '1', 'ind2' => '4',
              'subfields' => [
                { '6' => '610-01' },
                { 'a' => '辽宁省 (China).' },
                { 'b' => '谘议局' },
                { 'x' => 'History' },
                { 'v' => 'Sources.' }
              ]
            } }
          ]
        }
      end

      it 'returns organization with multiple scripts' do
        expect(build).to eq [
          { value: 'Liaoning Sheng (China). Zi yi ju', type: 'organization' },
          { value: '辽宁省 (China). 谘议局', type: 'organization' },
          { value: 'History', type: 'topic' },
          { value: 'Sources.', type: 'genre' }
        ]
      end
    end

    context 'with title + organization with multiple scripts (610 with $t/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '610' => {
              'ind1' => '1', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Liaoning Sheng (China).' },
                { 'b' => 'Zi yi ju' },
                { 't' => 'Title' }
              ]
            } },
            { '880' => {
              'ind1' => '1', 'ind2' => '4',
              'subfields' => [
                { '6' => '610-01' },
                { 'a' => '辽宁省 (China).' },
                { 'b' => '谘议局' },
                { 't' => 'Title' }
              ]
            } }
          ]
        }
      end

      it 'returns title with multiple scripts' do
        expect(build).to eq [
          { value: 'Liaoning Sheng (China). Zi yi ju Title', type: 'title' },
          { value: '辽宁省 (China). 谘议局 Title', type: 'title' }
        ]
      end
    end

    context 'with event with multiple scripts (611/880)' do
      # See a11610861
      let(:marc_hash) do
        {
          'fields' => [
            { '611' => {
              'ind1' => '2', 'ind2' => '7',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Demonstrations (Tunisia : 2010-)' },
                { '2' => 'fast' },
                { '0' => '(OCoLC)fst01907493' }
              ]
            } },
            { '880' => {
              'ind1' => '2', 'ind2' => '7',
              'subfields' => [
                { '6' => '611-01//r' },
                { 'a' => 'الثورة التونسية، 2010-' },
                { '2' => 'local/OSU' }
              ]
            } }
          ]
        }
      end

      it 'returns event with multiple scripts' do
        expect(build).to eq [
          { value: 'Demonstrations (Tunisia : 2010-)', type: 'event' },
          { value: 'الثورة التونسية، 2010-', type: 'event' }
        ]
      end
    end

    context 'with title + event with multiple scripts (611 with $t/880)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '611' => {
              'ind1' => '2', 'ind2' => '7',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Demonstrations (Tunisia : 2010-)' },
                { 't' => 'Title' },
                { '2' => 'fast' },
                { '0' => '(OCoLC)fst01907493' }
              ]
            } },
            { '880' => {
              'ind1' => '2', 'ind2' => '7',
              'subfields' => [
                { '6' => '611-01//r' },
                { 'a' => 'الثورة التونسية، 2010-' },
                { 't' => 'Title' },
                { '2' => 'local/OSU' }
              ]
            } }
          ]
        }
      end

      it 'returns title with multiple scripts' do
        expect(build).to eq [
          { value: 'Demonstrations (Tunisia : 2010-) Title', type: 'title' },
          { value: 'الثورة التونسية، 2010- Title', type: 'title' }
        ]
      end
    end

    context 'with title with multiple scripts (630/880)' do
      # See a10460841
      let(:marc_hash) do
        {
          'fields' => [
            { '630' => {
              'ind1' => '0', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Shu jing.' },
                { '0' => '(SIRSI)950788' }
              ]
            } },
            { '880' => {
              'ind1' => '0', 'ind2' => '0',
              'subfields' => [
                { '6' => '630-01' },
                { 'a' => '書經.' }
              ]
            } }
          ]
        }
      end

      it 'returns title with multiple scripts' do
        expect(build).to eq [
          { value: 'Shu jing.', type: 'title' },
          { value: '書經.', type: 'title' }
        ]
      end
    end

    context 'with time with multiple scripts (648/880)' do
      # See a13450163
      let(:marc_hash) do
        {
          'fields' => [
            { '648' => {
              'ind1' => ' ', 'ind2' => '7',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => '1919' },
                { '2' => 'fast' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '7',
              'subfields' => [
                { '6' => '648-01//r' },
                { 'a' => '١٩١٩' },
                { '2' => 'qrmak' }
              ]
            } }
          ]
        }
      end

      it 'returns time with multiple scripts' do
        expect(build).to eq [
          { value: '1919', type: 'time' },
          { value: '١٩١٩', type: 'time' }
        ]
      end
    end

    context 'with topic with multiple scripts (650/880)' do
      # See a13355540
      let(:marc_hash) do
        {
          'fields' => [
            { '650' => {
              'ind1' => '0', 'ind2' => '7',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Nong ye jing ji' },
                { 'x' => 'jing ji jian she' },
                { 'z' => 'He nan.' },
                { '2' => 'cct' }
              ]
            } },
            { '880' => {
              'ind1' => '0', 'ind2' => '7',
              'subfields' => [
                { '6' => '650-01' },
                { 'a' => '农业经济' },
                { 'x' => '经济建设' },
                { 'z' => '河南.' },
                { '2' => 'cct' }
              ]
            } }
          ]
        }
      end

      it 'returns topic with multiple scripts' do
        expect(build).to eq [
          { value: 'Nong ye jing ji', type: 'topic' },
          { value: 'jing ji jian she', type: 'topic' },
          { value: 'He nan.', type: 'place' },
          { value: '农业经济', type: 'topic' },
          { value: '经济建设', type: 'topic' },
          { value: '河南.', type: 'place' }
        ]
      end
    end

    context 'with place with multiple scripts (651/880)' do
      # See a8834380
      let(:marc_hash) do
        {
          'fields' => [
            { '651' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Nagano-ken (Japan)' },
                { 'x' => 'Social life and customs.' },
                { '0' => '(SIRSI)2178329' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { '6' => '651-01' },
                { 'a' => '長野県 (Japan)' },
                { 'x' => 'Social life and customs.' }
              ]
            } }
          ]
        }
      end

      it 'returns place with multiple scripts' do
        expect(build).to eq [
          { value: 'Nagano-ken (Japan)', type: 'place' },
          { value: 'Social life and customs.', type: 'topic' },
          { value: '長野県 (Japan)', type: 'place' }
        ]
      end
    end

    context 'with uncontrolled topic with multiple scripts (653/880 ind2=blank)' do
      # See a11467872
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => ' ',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled topic with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'topic' },
          { value: '中国方志', type: 'topic' }
        ]
      end
    end

    context 'with uncontrolled topic with multiple scripts (653/880 ind2=0)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '0',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled topic with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'topic' },
          { value: '中国方志', type: 'topic' }
        ]
      end
    end

    context 'with uncontrolled person with multiple scripts (653/880 ind2=1)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '1',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '1',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled person with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'person' },
          { value: '中国方志', type: 'person' }
        ]
      end
    end

    context 'with uncontrolled organization with multiple scripts (653/880 ind2=2)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '2',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '2',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled organization with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'organization' },
          { value: '中国方志', type: 'organization' }
        ]
      end
    end

    context 'with uncontrolled event with multiple scripts (653/880 ind2=3)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '3',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '3',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled event with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'event' },
          { value: '中国方志', type: 'event' }
        ]
      end
    end

    context 'with uncontrolled chronological period with multiple scripts (653/880 ind2=4)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '4',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '4',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled time with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'time' },
          { value: '中国方志', type: 'time' }
        ]
      end
    end

    context 'with uncontrolled place with multiple scripts (653/880 ind2=5)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '5',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '5',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled place with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'place' },
          { value: '中国方志', type: 'place' }
        ]
      end
    end

    context 'with uncontrolled genre with multiple scripts (653/880 ind2=6)' do
      let(:marc_hash) do
        {
          'fields' => [
            { '653' => {
              'ind1' => ' ', 'ind2' => '6',
              'subfields' => [
                { '6' => '880-01' },
                { 'a' => 'Zhongguo fang zhi' }
              ]
            } },
            { '880' => {
              'ind1' => ' ', 'ind2' => '6',
              'subfields' => [
                { '6' => '653-01' },
                { 'a' => '中国方志' }
              ]
            } }
          ]
        }
      end

      it 'returns uncontrolled genre with multiple scripts' do
        expect(build).to eq [
          { value: 'Zhongguo fang zhi', type: 'genre' },
          { value: '中国方志', type: 'genre' }
        ]
      end
    end
  end
end
