# frozen_string_literal: true

module Cocina
  # builds the Description subschema for ETDs
  class EtdDescriptionBuilder
    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      {
        title: build_title,
        contributor: build_contributors,
        event: [build_submission, build_conferral, build_publication, build_copyright],
        form: build_form,
        language: build_language,
        note: build_notes,
        identifier: build_identifier,
        purl: build_purl,
        url: build_url,
        marcEncodedData: build_marc_encoded_data,
        adminMetadata: build_admin_metadata
      }
    end

    private

    attr_reader :item

    def properties
      @properties ||= item.datastreams['properties']
    end

    def readers
      @readers ||= Nokogiri::XML(item.datastreams['readers'].content)
    end

    def build_title
      [{ value: item.title, status: 'primary' }]
    end

    def build_contributors
      [].tap do |contributors|
        contributors << build_author
        contributors.concat(build_advisors)
        contributors.concat(build_readers)
      end
    end

    def build_author
      build_person(item.name, item.suffix).tap do |person|
        person[:status] = 'primary'
        person[:role] = [
          {
            value: 'author',
            code: 'aut',
            uri: 'http://id.loc.gov/vocabulary/relators/aut',
            source: {
              code: 'marcrelator',
              uri: 'http://id.loc.gov/vocabulary/relators/'
            }
          },
          {
            value: 'author',
            uri: 'http://rdaregistry.info/Elements/a/P50195',
            source: {
              uri: 'http://www.rdaregistry.info/Elements/a/'
            }
          }
        ]
      end
    end

    def build_advisors
      readers.search('//reader[readerrole ="Advisor" or readerrole ="Co-Adv" or readerrole = "Dissertation Co-Advisor" or readerrole = "Co-Adv"]').map do |reader_elem|
        build_advisor(reader_elem)
      end
    end

    def build_advisor(reader_elem)
      build_person(reader_elem.at('name').text, reader_elem.at('suffix').text).tap do |advisor|
        advisor[:role] = [
          {
            value: reader_elem.at('readerrole').text,
            source: {
              value: 'ETD reader roles'
            }
          },
          {
            value: 'degree supervisor',
            code: 'dgs',
            uri: 'http://id.loc.gov/vocabulary/relators/dgs',
            source: {
              code: 'marcrelator',
              uri: 'http://id.loc.gov/vocabulary/relators/'
            }
          },
          {
            value: 'degree supervisor',
            uri: 'http://rdaregistry.info/Elements/a/P50091',
            source: {
              uri: 'http://www.rdaregistry.info/Elements/a/'
            }
          }
        ]
      end
    end

    def build_readers
      readers.search('//reader[readerrole = "Reader" or readerrole ="Rdr" or readerrole = "Outside Reader" or readerrole = "Engineers Thesis/Project Adv"]').map do |reader_elem|
        build_reader(reader_elem)
      end
    end

    def build_reader(reader_elem)
      build_person(reader_elem.at('name').text, reader_elem.at('suffix').text).tap do |advisor|
        advisor[:role] = [
          {
            value: reader_elem.at('readerrole').text,
            source: {
              value: 'ETD reader roles'
            }
          },
          {
            value: 'thesis advisor',
            code: 'ths',
            uri: 'http://id.loc.gov/vocabulary/relators/ths',
            source: {
              code: 'marcrelator',
              uri: 'http://id.loc.gov/vocabulary/relators/'
            }
          },
          {
            value: 'degree committee member',
            uri: 'http://rdaregistry.info/Elements/a/P50257',
            source: {
              uri: 'http://www.rdaregistry.info/Elements/a/'
            }
          }
        ]
      end
    end

    def build_person(name, suffix = nil)
      {
        name: [
          {
            value: build_name(name, suffix),
            type: 'inverted name'
          }
        ],
        type: 'person'
      }.tap do |person|
        # Names with suffixes get a structuredValue
        if suffix.present?
          person[:name] << {
            structuredValue: [
              {
                value: item.name,
                type: 'inverted name'
              },
              {   value: item.suffix,
                  type: 'name suffix' }
            ]
          }
        end
      end
    end

    def build_name(name, suffix)
      return name if suffix.blank?

      "#{name}, #{suffix}"
    end

    def build_reverse_name(name, suffix)
      build_name(name.split(/, */).reverse.join(' '), suffix)
    end

    def build_submission
      {
        type: 'thesis submission',
        date: [
          {
            value: build_submit_date
          }
        ],
        contributor: [
          {
            name: [
              {
                structuredValue: [
                  {
                    value: 'Stanford University',
                    type: 'university',
                    uri: 'http://id.loc.gov/authorities/names/n79054636',
                    source: {
                      code: 'lcnaf',
                      uri: 'http://id.loc.gov/authorities/names/'
                    }
                  },
                  {
                    value: item.schoolname,
                    type: 'school'
                  },
                  {
                    value: item.department,
                    type: 'department'
                  }
                ]
              }
            ],
            type: 'organization',
            role: [
              {
                value: 'degree granting institution',
                code: 'dgg',
                uri: 'http://id.loc.gov/vocabulary/relators/dgg',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              },
              {
                value: 'degree granting institution',
                uri: 'http://rdaregistry.info/Elements/a/P50003',
                source: {
                  uri: 'http://www.rdaregistry.info/Elements/a/'
                }
              }
            ]
          }
        ]
      }
    end

    def build_conferral
      {
        type: 'degree conferral',
        date: [
          {
            value: item.degreeconfyr,
            encoding: %w[edtf w3cdtf marc iso8601]
          }
        ],
        note: [
          {
            value: item.degree,
            type: 'degree type'
          }
        ],
        contributor: [
          {
            name: [
              {
                value: 'Stanford University',
                uri: 'http://id.loc.gov/authorities/names/n79054636',
                source: {
                  code: 'lcnaf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              }
            ],
            type: 'organization',
            role: [
              {
                value: 'degree granting institution',
                code: 'dgg',
                uri: 'http://id.loc.gov/vocabulary/relators/dgg',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              },
              {
                value: 'degree granting institution',
                uri: 'http://rdaregistry.info/Elements/a/P50003',
                source: {
                  uri: 'http://www.rdaregistry.info/Elements/a/'
                }
              }
            ]
          }
        ]
      }
    end

    def build_publication
      {
        type: 'publication',
        date: [
          {
            value: build_publication_date,
            "encoding": %w[edtf w3cdtf marc iso8601]
          }
        ],
        location: [
          {
            value: 'Stanford (Calif.)',
            uri: 'http://id.loc.gov/authorities/names/n50046557',
            source: {
              code: 'lcnaf',
              uri: 'http://id.loc.gov/authorities/names/'
            }
          },
          {
            value: 'California',
            code: 'cau',
            uri: 'http://id.loc.gov/vocabulary/countries/cau',
            source: {
              code: 'marccountry',
              uri: 'http://id.loc.gov/vocabulary/countries/'
            }
          }
        ],
        contributor: [
          {
            name: [
              {
                value: 'Stanford University',
                uri: 'http://id.loc.gov/authorities/names/n79054636',
                source: {
                  code: 'lcnaf',
                  uri: 'http://id.loc.gov/authorities/names/'
                }
              }
            ],
            type: 'organization',
            role: [
              {
                value: 'publisher',
                code: 'pbl',
                uri: 'http://id.loc.gov/vocabulary/relators/pbl',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              },
              {
                value: 'publisher',
                uri: 'http://rdaregistry.info/Elements/a/P50203',
                source: {
                  uri: 'http://www.rdaregistry.info/Elements/a/'
                }
              }
            ]
          }
        ],
        note: [
          {
            value: 'monographic',
            type: 'issuance',
            uri: 'http://id.loc.gov/vocabulary/issuance/mono',
            source: {
              uri: 'http://id.loc.gov/vocabulary/issuance/'
            }
          }
        ],
        structuredValue: [
          {
            value: '[Stanford, California]',
            type: 'publication statement place',
            standard: ['RDA']
          },
          {
            value: '[Stanford University]',
            type: 'publication statement publisher',
            standard: ['RDA']
          },
          {
            value: build_publication_date,
            type: 'publication statement date',
            standard: ['RDA']
          }
        ]
      }
    end

    def build_copyright
      {
        type: 'copyright',
        date: [
          {
            value: build_copyright_date,
            encoding: %w[edtf w3cdtf marc iso8601]
          }
        ],
        structuredValue: [
          {
            value: "©#{build_copyright_date}",
            type: 'copyright statement',
            standard: ['RDA']
          }
        ]
      }
    end

    def build_form
      [
        {
          value: 'computer',
          type: 'media',
          uri: 'http://id.loc.gov/vocabulary/mediaTypes/c',
          source: {
            code: 'rdamedia',
            uri: 'http://id.loc.gov/vocabulary/mediaTypes/'
          }
        },
        {
          value: 'online resource',
          type: 'carrier',
          uri: 'http://id.loc.gov/vocabulary/carriers/cr',
          source: {
            code: 'rdacarrier',
            uri: 'http://id.loc.gov/vocabulary/carriers/'
          }
        },
        {
          value: '1 online resource',
          type: 'extent',
          "standard": ['RDA']
        },
        {
          value: 'text',
          type: 'resource type',
          source: {
            value: 'MODS resource type'
          }
        },
        {
          value: 'text',
          type: 'content type',
          uri: 'http://id.loc.gov/vocabulary/contentTypes/txt',
          source: {
            code: 'rdacontent',
            uri: 'http://id.loc.gov/vocabulary/contentTypes/'
          }
        },
        {
          value: 'thesis',
          type: 'genre',
          uri: 'http://id.loc.gov/vocabulary/marcgt/the',
          source: {
            code: 'marcgt',
            uri: 'http://id.loc.gov/vocabulary/marcgt/'
          }
        }
      ]
    end

    def build_language
      [
        {
          value: 'English',
          code: 'eng',
          uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
          source: {
            code: 'iso239-2b',
            uri: 'http://id.loc.gov/vocabulary/iso639-2'
          }
        }
      ]
    end

    def build_notes
      [
        {
          value: item.abstract,
          type: 'summary'
        },
        build_submitted_to,
        {
          type: 'thesis',
          structuredValue: [
            {
              value: 'Thesis',
              type: 'note'
            },
            {
              value: item.degree,
              type: 'degree'
            },
            {
              value: 'Stanford University',
              type: 'university'
            },
            {
              value: item.degreeconfyr,
              type: 'date'
            }
          ]
        },
        {
          value: "#{build_reverse_name(item.name, item.suffix)}.",
          type: 'statement of responsibility',
          standard: ['RDA']
        }
      ]
    end

    def build_submitted_to
      name = if /Business/.match?(item.schoolname)
               'Graduate School of Business'
             elsif /Law/.match?(item.schoolname)
               'School of Law'
             elsif /Law/.match?(item.schoolname)
               'Graduate School of Education'
             else
               "Department of #{item.department}"
             end
      {
        value: "Submitted to the #{name}."
      }
    end

    def build_identifier
      [
        {
          value: item.dissertation_id,
          type: 'ETD ID'
        }
      ]
    end

    def build_purl
      "http://purl.stanford.edu/#{raw_druid}"
    end

    def raw_druid
      item.pid.split(':')[1]
    end

    def build_url
      [
        {
          value: "https://etd.stanford.edu/view/#{item.dissertation_id}",
          type: 'ETD'
        }
      ]
    end

    def build_marc_encoded_data
      [
        {
          value: '     nam a       3i',
          type: 'leader'
        },
        {
          value: "dor#{raw_druid}",
          type: '001'
        },
        {
          value: 'm        d',
          type: '006'
        },
        {
          value: 'cr un',
          type: '007'
        },
        {
          value: "170607t#{build_publication_date}#{build_copyright_date}cau     om    000 0 eng d",
          type: '008'
        }
      ]
    end

    def build_admin_metadata
      {
        event: build_admin_events,
        contributor: build_admin_contributors,
        language: build_admin_language
      }
    end

    def build_admin_events
      # Since this is being dynamically generated, setting both to today
      [
        {
          type: 'creation',
          date: [
            {
              value: today,
              "encoding": ['w3cdtf']
            }
          ]
        },
        {
          type: 'last modification',
          date: [
            {
              value: today,
              "encoding": ['w3cdtf']
            }
          ]
        }
      ]
    end

    def build_admin_contributors
      [
        {
          name: [
            {
              value: 'ETD application'
            }
          ],
          role: [
            {
              value: 'data source'
            }
          ]
        },
        {
          name: [
            {
              code: 'CSt',
              uri: 'http://id.loc.gov/vocabulary/organizations/cst',
              source: {
                code: 'marcorg',
                uri: 'http://id.loc.gov/vocabulary/organizations/'
              }
            }
          ],
          role: [
            {
              value: 'original cataloging agency'
            }
          ]
        },
        {
          name: [
            {
              code: 'CSt',
              uri: 'http://id.loc.gov/vocabulary/organizations/cst',
              source: {
                code: 'marcorg',
                uri: 'http://id.loc.gov/vocabulary/organizations/'
              }
            }
          ],
          role: [
            {
              value: 'transcribing agency'
            }
          ]
        }
      ]
    end

    def build_admin_language
      [
        {
          value: 'English',
          code: 'eng',
          uri: 'http://id.loc.gov/vocabulary/iso639-2/eng',
          source: {
            code: 'iso239-2b',
            uri: 'http://id.loc.gov/vocabulary/iso639-2'
          }
        }
      ]
    end

    def today
      Time.zone.today.to_s
    end

    def build_copyright_date
      if item.submit_date
        build_submit_date
      else
        item.degreeconfyr
      end
    end

    def build_submit_date
      Time.zone.at(item.submit_date.to_i).year.to_s
    end

    def build_publication_date
      # Note that if this wasn't a mapping, the publication date would be the current year, not the submit date.
      build_submit_date
    end
  end
end
