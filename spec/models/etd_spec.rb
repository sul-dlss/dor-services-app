# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Etd do
  subject(:instance) { described_class.new }

  describe '#datastreams' do
    subject(:datastreams) { instance.datastreams }

    it 'has a contentMetadata' do
      expect(datastreams['contentMetadata']).to be_instance_of Dor::ContentMetadataDS
    end
  end
end
