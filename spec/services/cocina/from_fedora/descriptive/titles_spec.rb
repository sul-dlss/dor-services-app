# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::Descriptive::Titles do
  describe '.build' do
    subject(:build) { described_class.build(ng_xml) }

    context 'when the object has no title' do
      let(:ng_xml) { Dor::Item.new.descMetadata.ng_xml }

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
      end
    end
  end
end
