# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::FileSets do
  describe '.resource_type' do
    subject { described_class.resource_type(node) }

    let(:node) { Nokogiri::XML::DocumentFragment.parse("<resource type=\"#{type}\" />").at_css('resource') }

    context 'when type is main-augmented (ETDs)' do
      let(:type) { 'main-augmented' }

      it { is_expected.to eq 'http://cocina.sul.stanford.edu/models/resources/main-augmented.jsonld' }
    end

    context 'when type is 3d' do
      let(:type) { '3d' }

      it { is_expected.to eq 'http://cocina.sul.stanford.edu/models/resources/3d.jsonld' }
    end
  end
end
