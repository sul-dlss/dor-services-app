# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Indexing::CompositeFacetValue do
  describe '.build' do
    it 'joins the label and druid with a colon' do
      expect(described_class.build(label: 'Stanford Theses', id: 'druid:bc123df4567'))
        .to eq 'Stanford Theses:druid:bc123df4567'
    end

    it 'keeps a colon-containing label intact' do
      expect(described_class.build(label: 'Title: A Subtitle', id: 'druid:bc123df4567'))
        .to eq 'Title: A Subtitle:druid:bc123df4567'
    end

    it 'joins the label and a URI with a colon' do
      expect(described_class.build(label: 'CC Zero 1.0',
                                   id: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode'))
        .to eq 'CC Zero 1.0:https://creativecommons.org/publicdomain/zero/1.0/legalcode'
    end
  end
end
