# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::RestructureH3ContributorOrcids do
  subject(:migrator) { described_class.new(repository_object) }

  let(:repository_object) do
    create(:repository_object, :with_repository_object_version,
           repository_object_version: build(:repository_object_version, label: 'Test DRO', description:))
  end
  let(:description) do
    {
      'title' => 'Test Title',
      'contributor' => contributors,
      'purl' => 'https://purl.stanford.edu'
    }
  end
  let(:contributors) do
    [
      contributor_with_orcid_needing_migration,
      contributor_with_orcid_not_needing_migration,
      contributor_without_orcid
    ]
  end
  let(:contributor_with_orcid_needing_migration) do
    {
      name: [
        {
          structuredValue: [
            {
              value: 'Michael J.',
              type: 'forename'
            },
            {
              value: 'Giarlo',
              type: 'surname'
            }
          ]
        }
      ],
      type: 'person',
      status: 'primary',
      role: [
        {
          value: 'author',
          code: 'aut',
          uri: 'http://id.loc.gov/vocabulary/relators/aut',
          source: {
            code: 'marcrelator',
            uri: 'http://id.loc.gov/vocabulary/relators/'
          }
        }
      ],
      identifier: [
        {
          value: '0000-0002-2100-6108',
          type: 'ORCID',
          source: {
            uri: 'https://orcid.org'
          }
        }
      ]
    }.with_indifferent_access
  end
  let(:contributor_with_orcid_not_needing_migration) do
    {
      name: [
        {
          structuredValue: [
            {
              value: 'Jane X.',
              type: 'forename'
            },
            {
              value: 'Doe',
              type: 'surname'
            }
          ]
        }
      ],
      type: 'person',
      status: 'primary',
      role: [
        {
          value: 'author',
          code: 'aut',
          uri: 'http://id.loc.gov/vocabulary/relators/aut',
          source: {
            code: 'marcrelator',
            uri: 'http://id.loc.gov/vocabulary/relators/'
          }
        }
      ],
      identifier: [
        {
          uri: 'https://orcid.org/0000-0099-9999-9999',
          type: 'ORCID'
        }
      ]
    }.with_indifferent_access
  end
  let(:contributor_without_orcid) do
    {
      name: [
        {
          value: 'Foo Z. Bar'
        }
      ],
      type: 'person',
      status: 'primary',
      role: [
        {
          value: 'author',
          code: 'aut',
          uri: 'http://id.loc.gov/vocabulary/relators/aut',
          source: {
            code: 'marcrelator',
            uri: 'http://id.loc.gov/vocabulary/relators/'
          }
        }
      ],
      identifier: [
        {
          value: 'https://foo.org/bar/',
          type: 'foobar'
        }
      ]
    }.with_indifferent_access
  end

  describe '#migrate?' do
    it 'returns true' do
      expect(migrator.migrate?).to be true
    end
  end

  describe 'migrate' do
    it 'restructures the ORCID identifier in the contributor that needs it' do
      migrator.migrate
      expect(repository_object.versions.last.description['contributor']).to eq(
        [
          {
            name: [
              {
                structuredValue: [
                  {
                    value: 'Michael J.',
                    type: 'forename'
                  },
                  {
                    value: 'Giarlo',
                    type: 'surname'
                  }
                ]
              }
            ],
            type: 'person',
            status: 'primary',
            role: [
              {
                value: 'author',
                code: 'aut',
                uri: 'http://id.loc.gov/vocabulary/relators/aut',
                source: {
                  code: 'marcrelator',
                  uri: 'http://id.loc.gov/vocabulary/relators/'
                }
              }
            ],
            identifier: [
              {
                uri: 'https://orcid.org/0000-0002-2100-6108',
                type: 'ORCID'
              }
            ]
          }.with_indifferent_access,
          contributor_with_orcid_not_needing_migration,
          contributor_without_orcid
        ]
      )
    end
  end

  describe '#publish?' do
    it 'returns false since using base default' do
      expect(migrator.publish?).to be false
    end
  end

  describe '#version?' do
    it 'returns false since using base default' do
      expect(migrator.version?).to be false
    end
  end
end
