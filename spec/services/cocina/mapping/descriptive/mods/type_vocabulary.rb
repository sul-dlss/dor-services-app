# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Cocina type vocabulary' do
  context 'access' do
    describe 'access.accessContact' do
      let(:types) do
        [
          {
            value: 'email',
            description: 'Email address for a contact person concerning the resource.',
            context_mods: [ 'note' ]
          },
          {
            value: 'repository',
            description: 'Institution providing access to the resource.',
            context_mods: [ 'location/physicalLocation' ]
          }
        ]
      end
    end

    describe 'access.digitalLocation' do
      let(:types) do
        [
          {
            value: 'discovery',
            description: 'Online location for the purpose of discovering the resource.',
            context_mods: [ 'location/physicalLocation' ]
          }
        ]
      end
    end

    describe 'access.physicalLocation' do
      let(:types) do
        [
          {
            value: 'location',
            description: 'Physical location of the resource, or path to the resource on a hard drive or disk.',
            context_mods: [ 'location/physicalLocation' ]
          },
          {
            value: 'shelf locator',
            description: 'Identifier or shelfmark for the location of the resource.',
            context_mods: [ 'location/shelfLocator' ]
          }
        ]
      end
    end
  end

  context 'contributor' do
    describe 'contributor' do
      let(:types) do
        [
          {
            value: 'conference',
            description: 'An event focusing on a particular topic or discipline.',
            context_mods: [ 'name' ]
          },
          {
            value: 'event'
          },
          {
            value: 'family',
            description: 'A group of related individuals.',
            context_mods: [ 'name' ]
          },
          {
            value: 'organization',
            description: 'An institution or other corporate body.',
            context_mods: [ 'name' ]
          },
          {
            value: 'person',
            description: 'An individual identity.',
            context_mods: [ 'name' ]
          },
          {
            value: 'unspecified others',
            description: 'Designator for one or more additional contributors not named.',
            context_mods: [ 'name' ]
          }
        ]
      end
    end

    describe 'contributor.name' do
      let(:types) do
        [
          {
            value: 'display',
            description: 'Form of name to prefer for display.',
            context_mods: [ 'name/displayForm' ]
          },
          {
            value: 'forename',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'inverted full name',
          },
          {
            value: 'pseudonym',
          },
          {
            value: 'surname',
            description: 'Last or family name',
            context_mods: [ 'name/namePart' ]
          }
        ]
      end
    end

    describe 'contributor.name.groupedValue' do
      let(:types) do
        [
          {
            value: 'alternative',
            description: 'Additional nonpreferred form of name.',
            context_mods: [ 'name/alternativeName' ]
          },
          {
            value: 'name',
            description: 'Name form preferred over other alternative forms of name.',
            context_mods: [ 'name' ]
          },
          {
            value: 'pseudonym',
            description: 'Name used that differs from legal or primary form of name.',
            context_mods: [ 'name/alternativeName' ]
          }
        ]
      end
    end

    describe 'contributor.name.parallelValue' do
      let(:types) do
        [
          {
            value: 'transliteration',
            description: 'Name originally in non-Latin script presented phonetically using Latin characters.',
            context_mods: [ 'name' ]
          }
        ]
      end
    end

    describe 'contributor.name.structuredValue' do
      let(:types) do
        [
          # needs to be updated in spec mapping
          {
            value: 'activity dates',
            description: 'The date or dates when someone was producing work.',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'forename',
            description: 'First or given name or names',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'life dates',
            description: 'Birth and death dates, or dates when an entity was in existence.',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'name',
            description: 'Name provided with additional information.',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'ordinal',
            description: 'Indicator that the name is one in a series (e.g. Elizabeth I, Martin Luther King, Jr.).',
          },
          {
            value: 'surname',
            description: 'Last or family name.',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'term of address',
            description: 'Title or other signifier associated with name.',
            context_mods: [ 'name/namePart' ]
          }
        ]
      end
    end
  end

  context 'event' do
    describe 'event' do
      let(:types) do
        [
          {
            value: 'creation',
            context_mods: [ 'originInfo',
                            'recordInfo/recordCreationDate' ]
          },
          {
            value: 'modification',
            context_mods: [ 'originInfo',
                            'recordInfo/recordChangeDate' ]
          },
          {
            value: 'publication',
            context_mods: [ 'originInfo',
                            'recordInfo/recordChangeDate' ]
          },
          {
            value: 'release',
            context_mods: [ 'originInfo',
                            'recordInfo/recordChangeDate' ]
          }
        ]
      end
    end

    describe 'event.date' do
      let(:types) do
        [
          {
            value: 'start',
            context_mods: [ 'originInfo/copyrightDate',
                            'originInfo/dateCaptured',
                            'originInfo/dateCreated',
                            'originInfo/dateIssued',
                            'originInfo/dateModified',
                            'originInfo/dateValid' ]
          },
          {
            value: 'end',
            context_mods: [ 'originInfo/copyrightDate',
                            'originInfo/dateCaptured',
                            'originInfo/dateCreated',
                            'originInfo/dateIssued',
                            'originInfo/dateModified',
                            'originInfo/dateValid' ]
          }
        ]
      end
    end
  end

  context 'form' do
    describe 'form' do
      let(:types) do
        [
          {
            value: 'data format',
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'digital origin',
            context_mods: [ 'physicalDescription/digitalOrigin' ]
          }
          {
            value: 'extent',
            context_mods: [ 'physicalDescription/extent' ]
          },
          {
            value: 'form',
            context_mods: [ 'physicalDescription/form' ]
          }
          {
            value: 'genre',
            context_mods: [ 'genre' ]
          },
          {
            value: 'map coordinates',
            context_mods: [ 'subject/cartographics/coordinates' ]
          },
          {
            value: 'map projection',
            context_mods: [ 'subject/cartographics/projection' ]
          },
          {
            value: 'map scale',
            context_mods: [ 'subject/cartographics/scale' ]
          },
          {
            value: 'media type',
            context_mods: [ 'physicalDescription/internetMediaType',
                            'geoExtension' ],
          },
          {
            value: 'reformatting quality',
            context_mods: [ 'physicalDescription/reformattingQuality' ]
          },
          {
            value: 'resource type',
            context_mods: [ 'typeOfResource' ]
          },
          {
            value: 'type',
            context_mods: [ 'geoExtension' ]
          }
        ]
      end
    end

    describe 'form.groupedValue' do
      let(:types) do
        [
          {
            value: 'extent',
            context_mods: [ 'physicalDescription/extent' ]
          }
          {
            value: 'form',
            context_mods: [ 'physicalDescription/form' ]
          }
        ]
      end
    end

    describe 'form.structuredValue' do
      let(:types) do
        [
          {
            value: 'type',
            context_h2: [ 'primary resource type' ]
          },
          {
            value: 'subtype',
            context_h2: [ 'additional resource type' ]
          }
        ]
      end
    end
  end

  context 'identifier' do
    describe 'identifier' do
      let(:types) do
        [
          {
            value: 'ARK',
            context_mods: [ 'identifier' ]
          },
          {
            value: 'ISBN',
            context_mods: [ 'identifier' ]
          },
          {
            value: 'LCCN',
            context_mods: [ 'identifier' ]
          },
          {
            value: 'local',
            context_mods: [ 'identifier' ]
          },
          {
            value: 'OCLC',
            context_mods: [ 'identifier',
                            'recordInfo/recordIdentifier' ]
          },
          # Spec needs to be updated to use identifier
          {
            value: 'ORCID',
            context_cocina: [ 'contributor' ],
            context_mods: [ 'name/nameIdentifier']
          },
          {
            value: 'SIRSI',
            context_cocina: [ 'adminMetadata' ],
            context_mods: [ 'recordInfo/recordIdentifier' ]
          },
          {
            value: 'SUL catalog key',
            context_cocina: [ 'adminMetadata' ],
            context_mods: [ 'recordInfo/recordIdentifier' ]
          },
          {
            value: 'Wikidata',
            context_mods: [ 'name' ]
          }
        ]
      end
    end
  end

  context 'note' do
    describe 'note' do
      let(:types) do
        [
          {
            value: 'access restriction',
            context_cocina: [ 'access' ],
            context_mods: [ 'accessCondition' ]
          },
          {
            value: 'affiliation',
            context_cocina: [ 'contributor' ],
            context_mods: [ 'name' ]
          },
          {
            value: 'anchor',
            context_mods: [ '@ID' ]
          },
          {
            value: 'citation status',
            context_cocina: [ 'contributor' ]
          }
          {
            value: 'collation',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/note' ]
          },
          {
            value: 'description',
            context_cocina: [ 'contributor' ],
            context_mods: [ 'name' ]
          },
          {
            value: 'dimensions',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/note' ]
          },
          {
            value: 'display label',
            context_cocina: [ 'access' ],
            context_mods: [ 'location/url' ]
          },
          {
            value: 'foliation',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/note' ]
          },
          {
            value: 'genre type',
            context_cocina: [ 'form' ],
            context_mods: [ 'genre' ]
          },
          # FIX ME in mapping spec
          {
            value: 'hand note',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/note' ]
          },
          {
            value: 'layout',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/note' ]
          },
          {
            value: 'license',
            context_cocina: [ 'access' ],
            context_mods: [ 'accessCondition' ]
          },
          {
            value: 'material',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/note' ]
          },
          {
            value: 'nonsorting character count',
            context_cocina: [ 'title' ]
          },
          {
            value: 'other relation type',
            context_mods: [ 'relatedItem/note' ]
          },
          {
            value: 'part',
            context_mods: [ 'note' ]
          },
          {
            value: 'preferred citation',
            context_mods: [ 'note' ]
          },
          {
            value: 'record origin',
            context_cocina: [ 'adminMetadata' ],
            context_mods: [ 'recordInfo/recordOrigin' ]
          },
          {
            value: 'statement of responsibility',
            context_mods: [ 'note' ]
          }
          {
            value: 'summary',
            context_mods: [ 'abstract' ]
          },
          {
            value: 'table of contents',
            context_mods: [ 'tableOfContents' ]
          },
          {
            value: 'target audience',
            context_mods: [ 'targetAudience' ]
          },
          {
            value: 'type',
            context_cocina: [ 'identifier' ],
            context_mods: [ 'identifier' ]
          },
          {
            value: 'unit',
            context_cocina: [ 'form' ],
            context_mods: [ 'physicalDescription/extent' ]
          },
          {
            value: 'use and reproduction',
            context_cocina: [ 'access' ],
            context_mods: [ 'accessCondition' ]
          }
        ]
      end
    end

    describe 'note.groupedValue' do
      let(:types) do
        [
          {
            value: 'caption',
            context_mods: [ 'part' ]
          },
          {
            value: 'date',
            context_mods: [ 'part' ]
          }
          {
            value: 'detail type',
            context_mods: [ 'part' ]
          },
          {
            value: 'extent unit',
            context_mods: [ 'part' ]
          },
          {
            value: 'list',
            context_mods: [ 'part' ]
          },
          {
            value: 'marker',
            context_mods: [ 'part/detail']
          },
          {
            value: 'number',
            context_mods: [ 'part']
          },
          {
            value: 'title',
            context_mods: [ 'part']
          },
          {
            value: 'text',
            context_mods: [ 'part']
          }
        ]
      end
    end
  end

  context 'relatedResource' do
    describe 'relatedResource' do
      let(:types) do
        [
          {
            value: 'has original version',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'has other format',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'has part',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'in series',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'other relation type',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'part of',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'referenced by',
            context_mods: [ 'relatedItem' ]
          },
          {
            value: 'related to',
            context_mods: [ 'relatedItem' ]
          }
        ]
      end
    end
  end

  context 'subject' do
    describe 'subject' do
      let(:types) do
        [
          {
            value: 'bounding box coordinates',
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'classification',
            context_mods: [ 'classification' ]
          },
          {
            value: 'conference',
            context_mods: [ 'subject/name' ]
          }
          {
            value: 'coverage',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'event',
          },
          {
            value: 'family',
            context_mods: [ 'subject/name' ]
          },
          {
            value: 'genre',
            context_mods: [ 'subject/genre' ]
          },
          {
            value: 'occupation',
            context_mods: [ 'subject/occupation' ]
          },
          {
            value: 'organization',
            context_mods: [ 'subject/name' ]
          },
          {
            value: 'person',
            context_mods: [ 'subject/name' ]
          },
          {
            value: 'place',
            context_mods: [ 'subject/geographic',
                            'subject/hierarchicalGeographic' ]
          },
          {
            value: 'point coordinates',
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'time',
            context_mods: [ 'subject/temporal' ]
          }
          {
            value: 'title',
            context_mods: [ 'subject/titleInfo' ]
          },
          {
            value: 'topic',
            context_mods: [ 'subject/topic' ]
          }
        ]
      end
    end

    describe 'subject.parallelValue' do
      let(:types) do
        [
          {
            value: 'display',
            context_mods: [ 'subject/name' ]
          }
        ]
      end
    end

    describe 'subject.structuredValue' do
      let(:types) do
        [
          {
            value: 'city',
            context_mods: [ 'subject/hierarchicalGeographic/city' ]
          },
          {
            value: 'continent',
            context_mods: [ 'subject/hierarchicalGeographic/continent' ]
          },
          {
            value: 'country',
            context_mods: [ 'subject/hierarchicalGeographic/country' ]
          },
          {
            value: 'end',
            context_mods: [ 'subject/temporal' ]
          },
          {
            value: 'east',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'forename',
            context_mods: [ 'subject/name/namePart' ]
          },
          {
            value: 'genre',
            context_mods: [ 'subject/genre' ]
          },
          {
            value: 'latitude',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'life dates',
            context_mods: [ 'subject/name/namePart' ]
          },
          {
            value: 'longitude',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'main title',
            context_mods: [ 'subject/titleInfo/title' ]
          },
          {
            value: 'name',
            context_mods: [ 'subject/name/namePart' ]
          },
          {
            value: 'north',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'part name',
            context_mods: [ 'subject/titleInfo/partName' ]
          },
          {
            value: 'person',
            context_mods: [ 'subject/name' ]
          },
          {
            value: 'place',
            context_mods: [ 'subject/geographic' ]
          },
          {
            value: 'south',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          },
          {
            value: 'start',
            context_mods: [ 'subject/temporal' ]
          },
          {
            value: 'surname',
            context_mods: [ 'subject/name/namePart' ]
          },
          {
            value: 'term of address',
            context_mods: [ 'subject/name/namePart' ]
          },
          {
            value: 'time',
            context_mods: [ 'subject/temporal' ]
          },
          {
            value: 'title',
            context_mods: [ 'subject/titleInfo' ]
          },
          {
            value: 'topic',
            context_mods: [ 'subject/topic' ]
          },
          {
            value: 'west',
            context_cocina: [ 'geographic' ],
            context_mods: [ 'geoExtension' ]
          }
        ]
      end
    end
  end

  context 'title' do
    describe 'title' do
      let(:types) do
        [
          {
            value: 'abbreviated',
            context_mods: [ 'titleInfo' ]
          },
          {
            value: 'alternative',
            context_mods: [ 'titleInfo' ]
          },
          {
            value: 'parallel'
          },
          {
            value: 'supplied',
            context_mods: [ 'titleInfo' ]
          },
          {
            value: 'transliterated',
            context_mods: [ 'titleInfo' ]
          },
          {
            value: 'uniform',
            context_mods: [ 'titleInfo' ]
          }
        ]
      end
    end

    describe 'title.parallelValue' do
      let(:types) do
        [
          {
            value: 'transliteration',
            description: 'Title originally in non-Latin script presented phonetically using Latin characters.',
            context_mods: [ 'titleInfo' ]
          }
        ]
      end
    end

    describe 'title.structuredValue' do
      let(:types) do
        [
          {
            value: 'main title',
            context_mods: [ 'titleInfo/title' ]
          },
          {
            value: 'name',
            context_mods: [ 'name' ]
          },
          {
            value: 'nonsorting characters',
            context_mods: [ 'titleInfo/nonSort' ]
          },
          {
            value: 'part name',
            context_mods: [ 'titleInfo/partName' ]
          },
          {
            value: 'part number',
            context_mods: [ 'titleInfo/partNumber' ]
          },
          {
            value: 'subtitle',
            context_mods: [ 'titleInfo/subtitle' ]
          },
          {
            value: 'title',
            context_mods: [ 'titleInfo/title' ]
          }
        ]
      end
    end

    describe 'title.structuredValue.structuredValue' do
      # Structured name and/or title as part of uniform title
      let(:types) do
        [
          {
            value: 'activity dates',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'forename',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'life dates',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'main title',
            context_mods: [ 'titleInfo/title' ]
          },
          {
            value: 'name',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'nonsorting characters',
            context_mods: [ 'titleInfo/nonSort' ]
          },
          {
            value: 'ordinal',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'part name',
            context_mods: [ 'titleInfo/partName' ]
          },
          {
            value: 'part number',
            context_mods: [ 'titleInfo/partNumber' ]
          },
          {
            value: 'subtitle',
            context_mods: [ 'titleInfo/subtitle' ]
          },
          {
            value: 'surname',
            context_mods: [ 'name/namePart' ]
          },
          {
            value: 'term of address',
            context_mods: [ 'name/namePart' ]
          }
        ]
      end
    end
  end
end
