# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::Indexers::AdministrativeTagIndexer do
  describe '#to_solr' do
    subject(:document) { indexer.to_solr }

    let(:indexer) { described_class.new(id: 'druid:rt923jk234', administrative_tags: tags) }

    let(:tags) do
      [
        'Google Books : Phase 1',
        'Google Books : Scan source STANFORD',
        'Project : Beautiful Books',
        'Project : Rare Books : Very Old Books',
        'Registered By : blalbrit',
        'DPG : Beautiful Books : Octavo : newpri',
        'Remediated By : 4.15.4'
      ]
    end

    it 'indexes all administrative tags' do
      expect(document).to include('tag_ssim' => tags) # for facet and display
      expect(document).to include('tag_text_unstemmed_im' => tags) # for search
      # rubocop:enable Style/StringHashKeys
    end

    it 'indexes exploded tags' do
      expect(document['exploded_nonproject_tag_ssimdv'])
        .to contain_exactly('Google Books', 'Google Books : Phase 1', 'Google Books',
                            'Google Books : Scan source STANFORD', 'Registered By',
                            'Registered By : blalbrit', 'DPG', 'DPG : Beautiful Books',
                            'DPG : Beautiful Books : Octavo',
                            'DPG : Beautiful Books : Octavo : newpri', 'Remediated By', 'Remediated By : 4.15.4')
      expect(document['exploded_project_tag_ssimdv']).to contain_exactly('Beautiful Books', 'Rare Books',
                                                                         'Rare Books : Very Old Books')
      expect(document).not_to have_key('exploded_registered_by_tag_ssim')
    end

    it 'indexes prefixed tags' do
      # rubocop:disable Style/StringHashKeys
      expect(document).to include(
        'project_tag_ssim' => ['Beautiful Books', 'Rare Books : Very Old Books'],
        'registered_by_tag_ssim' => ['blalbrit']
      )
      # rubocop:enable Style/StringHashKeys
    end
  end
end
