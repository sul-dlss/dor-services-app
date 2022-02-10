# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  describe '.for' do
    let(:dro_object) do
      Cocina::Models::DRO.new(externalIdentifier: 'druid:bc123df4567',
                              type: Cocina::Models::Vocab.object,
                              label: 'Some Label',
                              version: 1,
                              identification: {},
                              access: {},
                              structural: {},
                              administrative: { hasAdminPolicy: 'druid:fg890hx1234',
                                                releaseTags: [
                                                  {
                                                    who: 'dhartwig',
                                                    what: 'collection',
                                                    date: '2019-01-18T17:03:35.000+00:00',
                                                    to: 'Searchworks',
                                                    release: true
                                                  }
                                                ] })
    end

    it 'returns the hash of release tags' do
      expect(described_class.for(dro_object: dro_object)).to eq(
        'Searchworks' => {
          'release' => true
        }
      )
    end
  end
end
