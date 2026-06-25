# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Catalog::InstanceMarcBuilder do
  subject(:builder) { described_class.new(instance_hash:) }

  let(:folio_record) { builder.build }
  let(:instance_hash) do
    {
      'id' => '0e050e3f-b160-5f5d-9fdb-2d49305fbb0d',
      'hrid' => 'a8888',
      'source' => 'MARC',
      'title' => 'The title',
      'administrativeNotes' => [
        'NONLATINCJK/20130328/eoh'
      ],
      'alternativeTitles' => [
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => 'English title on container: Merited artiste Kim Gwang Suk\'s solos. 2'
        },
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => 'Kim Gwang Suk\'s solos. 2'
        },
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => 'At head of title on container: Konghun paeu'
        },
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => 'Konghun paeu Kim Kwang-suk tokch\'anggok chip. 2'
        },
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => '김 광숙 독창곡 집. 2 [sound recording].'
        },
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => 'At head of title on container: 공훈 배우'
        },
        {
          'authorityId' => nil,
          'alternativeTitleTypeId' => '35bbe7f2-1a49-11ed-861d-0242ac120002',
          'alternativeTitle' => '공훈 배우 김 광숙 독창곡 집. 2'
        }
      ],
      'identifiers' => [
        { 'value' => 'garbage' },
        { 'value' => '(OCoLC-M)948533645' },
        { 'value' => 'sn2021236856' },
        { 'value' => '   68038902 //r84' },
        { 'value' => '2381-5868' },
        { 'value' => '1485631076 (paperback)' },
        { 'value' => '9781485631071 (paperback)' }
      ],
      'languages' => [
        'eng',
        'kor'
      ],
      'contributors' => [
        {
          'authorityId' => nil,
          'contributorNameTypeId' => '2b94c631-fca9-4892-a730-03ee529ffe2a',
          'name' => 'Bezos, Jeffrey',
          'contributorTypeId' => '9f0a2cf0-7a9b-45a2-a403-f68d2850d07c',
          'contributorTypeText' => nil,
          'primary' => true
        },
        {
          'authorityId' => nil,
          'contributorNameTypeId' => '2b94c631-fca9-4892-a730-03ee529ffe2a',
          'name' => 'Joss, Robert Law',
          'contributorTypeId' => 'ac0baeb5-71e2-435f-aaf1-14b64e2ba700',
          'contributorTypeText' => 'speaker.',
          'primary' => false
        },
        {
          'authorityId' => nil,
          'contributorNameTypeId' => '2e48e713-17f3-4c13-a9f8-23845bb210aa',
          'name' => 'Stanford University. Graduate School of Business',
          'contributorTypeId' => '9f0a2cf0-7a9b-45a2-a403-f68d2850d07c',
          'contributorTypeText' => nil,
          'primary' => false
        }
      ],
      'editions' => [
        'Saihan.',
        '再板.'
      ],
      'classifications' => [
        {
          'classificationNumber' => 'UB247 P87 1993',
          'classificationTypeId' => 'ce176ace-a53e-4b4d-aa89-725ed7b2edac'
        }
      ],
      'publication' => [
        {
          'publisher' => 'Stanford Business School',
          'place' => '[Stanford, CA',
          'dateOfPublication' => '2000]',
          'role' => nil
        }
      ],
      'physicalDescriptions' => [
        '1 videodisc (60 min.) : sound, color ; 4 3/4 in.'
      ],
      'publicationFrequency' => [
        'Weekly, June 1946-',
        'Biweekly, 1939-June 1946',
        'Weekly or biweekly, Dec. 11, 1937-1938'
      ],
      'publicationRange' => [
        'Began with issue published Dec. 11, 1937; ceased in 1947?'
      ],
      'notes' => [
        {
          'instanceNoteTypeId' => '6a2533a7-4de2-4e64-8466-074c2fa9308c',
          'note' => 'Title supplied by cataloger',
          'staffOnly' => false
        },
        {
          'instanceNoteTypeId' => '43295b78-3bfa-4c28-bc7f-8d924f63493f',
          'note' => 'Recorded at Bishop Auditorium, Stanford Business School on Feb. 15, 2000',
          'staffOnly' => false
        },
        {
          'instanceNoteTypeId' => '10e2e11b-450f-45c8-b09b-0f819999966e',
          'note' => 'Jeff Bezos speakes to a Stanford Business audience about Amazon.com and urges the dot.com ' \
                    'entrepreneurs to not be too hasty in dismissing stock valuations of the Internet sector as ' \
                    'out of sync with reality',
          'staffOnly' => false
        },
        {
          'instanceNoteTypeId' => '95f62ca7-5df5-4a51-9890-d0ec3a34665f',
          'note' => 'DVD',
          'staffOnly' => false
        }
      ],
      'series' => [
        {
          'authorityId' => nil,
          'value' => 'View from the top'
        },
        {
          'authorityId' => nil,
          'value' => 'View from the top (Stanford, Calif.)'
        }
      ],
      'subjects' => [
        {
          'authorityId' => nil,
          'value' => 'Songs, Korean--Korea (North)',
          'sourceId' => nil,
          'typeId' => nil
        },
        {
          'authorityId' => nil,
          'value' => 'Songs, Russian',
          'sourceId' => nil,
          'typeId' => nil
        },
        {
          'authorityId' => nil,
          'value' => 'Songs, Chinese',
          'sourceId' => nil,
          'typeId' => nil
        }
      ],
      'electronicAccess' => [
        {
          'uri' => 'http://purl.stanford.edu/qh830pr6982',
          'publicNote' => 'Available to Stanford-affiliated users',
          'relationshipId' => '3b430592-2e09-4b48-9a0c-0636d66b9fb3'
        }
      ]
    }
  end

  describe '#build' do
    it 'builds the control number from the HRID' do
      expect(folio_record['001'].value).to eq('a8888')
    end

    it 'builds the ISBN from the identifiers' do
      expect(folio_record.fields('020').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: '1485631076 (paperback)')
      )
      expect(folio_record.fields('020').last.subfields).to contain_exactly(
        have_attributes(code: 'a', value: '9781485631071 (paperback)')
      )
    end

    it 'builds the LCCN from the identifiers' do
      expect(folio_record.fields('010').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: 'sn2021236856')
      )
      expect(folio_record.fields('010').last.subfields).to contain_exactly(
        have_attributes(code: 'a', value: '   68038902 //r84')
      )
    end

    it 'builds the ISSN from the identifiers' do
      expect(folio_record['022'].subfields).to contain_exactly(
        have_attributes(code: 'a', value: '2381-5868')
      )
    end

    it 'builds the OCLC number from the identifiers' do
      expect(folio_record['035'].subfields).to contain_exactly(
        have_attributes(code: 'a', value: '(OCoLC-M)948533645')
      )
    end

    it 'builds the languages from the languages' do
      expect(folio_record.fields('041').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'eng'),
        have_attributes(code: 'a', value: 'kor')
      )
    end

    it 'builds the authors from the contributors' do
      expect(folio_record.fields('100').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: 'Bezos, Jeffrey')
      )
      expect(folio_record.fields('700').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'Joss, Robert Law'),
        have_attributes(code: 'a', value: 'Stanford University. Graduate School of Business')
      )
    end

    it 'builds the title from the title' do
      expect(folio_record.fields('245').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: 'The title')
      )
    end

    it 'builds the editions from the editions' do
      expect(folio_record.fields('250').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'Saihan.'),
        have_attributes(code: 'a', value: '再板.')
      )
    end

    it 'builds the publication info from the publication' do
      expect(folio_record.fields('264').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: '[Stanford, CA'),
        have_attributes(code: 'b', value: 'Stanford Business School'),
        have_attributes(code: 'c', value: '2000]')
      )
    end

    it 'builds the physical description from the physicalDescriptions' do
      expect(folio_record.fields('300').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: '1 videodisc (60 min.) : sound, color ; 4 3/4 in.')
      )
    end

    it 'builds the publication frequency from the publicationFrequency' do
      expect(folio_record.fields('310').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'Weekly, June 1946-'),
        have_attributes(code: 'a', value: 'Biweekly, 1939-June 1946'),
        have_attributes(code: 'a', value: 'Weekly or biweekly, Dec. 11, 1937-1938')
      )
    end

    it 'builds the publication range from the publicationRange' do
      expect(folio_record.fields('362').first.subfields).to contain_exactly(
        have_attributes(code: 'a', value: 'Began with issue published Dec. 11, 1937; ceased in 1947?')
      )
    end

    it 'builds the notes from the notes' do
      expect(folio_record.fields('500').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'Title supplied by cataloger'),
        have_attributes(code: 'a', value: 'Recorded at Bishop Auditorium, Stanford Business School on Feb. 15, 2000'),
        have_attributes(code: 'a', value: 'Jeff Bezos speakes to a Stanford Business audience about Amazon.com and ' \
                                          'urges the dot.com entrepreneurs to not be too hasty in dismissing stock ' \
                                          'valuations of the Internet sector as out of sync with reality'),
        have_attributes(code: 'a', value: 'DVD')
      )
    end

    it 'builds the series from the series' do
      expect(folio_record.fields('490').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'View from the top'),
        have_attributes(code: 'a', value: 'View from the top (Stanford, Calif.)')
      )
    end

    it 'builds the subjects from the subjects' do
      expect(folio_record.fields('653').map(&:subfields).flatten).to contain_exactly(
        have_attributes(code: 'a', value: 'Songs, Korean--Korea (North)'),
        have_attributes(code: 'a', value: 'Songs, Russian'),
        have_attributes(code: 'a', value: 'Songs, Chinese')
      )
    end

    it 'builds the 999 field with the instance id' do
      expect(folio_record.fields('999').first.subfields).to contain_exactly(
        have_attributes(code: 'i', value: '0e050e3f-b160-5f5d-9fdb-2d49305fbb0d')
      )
    end
  end
end
