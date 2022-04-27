# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReleaseTags do
  describe '.for' do
    let(:cocina_item) do
      build(:dro).new(
        administrative: {
          hasAdminPolicy: 'druid:fg890hx1234',
          releaseTags: [
            {
              who: 'dhartwig',
              what: 'collection',
              date: '2019-01-18T17:03:35.000+00:00',
              to: 'Searchworks',
              release: true
            }
          ]
        }
      )
    end

    it 'returns the hash of release tags' do
      expect(described_class.for(cocina_object: cocina_item)).to eq(
        'Searchworks' => {
          'release' => true
        }
      )
    end
  end
end
