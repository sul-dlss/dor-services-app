# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::TitleMapper do
  describe '.build' do
    subject(:build) { described_class.build(object) }

    context 'when the object has no title' do
      let(:object) { Dor::Item.new }

      it 'raises and error' do
        expect { build }.to raise_error Cocina::Mapper::MissingTitle
      end
    end
  end
end
