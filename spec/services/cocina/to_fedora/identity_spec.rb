# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::Identity do
  subject(:apply) { described_class.update(datastream, uri) }

  let(:datastream) do
    Dor::IdentityMetadataDS.new.tap { |ds| ds.content = datastream_xml }
  end

  let(:fedora_object) do
    instance_double(Dor::Item, identityMetadata: datastream)
  end

  describe '#apply_release_tags' do
    subject(:apply_release_tags) { described_class.apply_release_tags(fedora_object, release_tags: release_tags) }

    let(:release_tags) do
      [
        Cocina::Models::ReleaseTag.new(
          to: 'Searchworks',
          who: 'bergeraj',
          what: 'self',
          release: true,
          date: '2021-07-01T12:12:12Z'
        )
      ]
    end

    let(:datastream_xml) do
      <<~XML
        <identityMetadata>
          <release what="self" to="Searchworks" who="jcoyne85" when="2021-06-28T19:11:26Z">true</release>
        </identityMetadata>
      XML
    end

    it 'overwrites the existing tags' do
      apply_release_tags
      expect(datastream.ng_xml).to be_equivalent_to <<~XML
        <identityMetadata>
          <release what="self" to="Searchworks" who="bergeraj" when="2021-07-01T12:12:12Z">true</release>
        </identityMetadata>
      XML
    end
  end
end
