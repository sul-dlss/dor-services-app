# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ToFedora::ProcessTag do
  subject(:apply) { described_class.map(type, direction) }

  let(:direction) { nil }

  describe 'with map' do
    let(:type) { Cocina::Models::Vocab.map }

    it { is_expected.to eq 'Process : Content Type : Map' }
  end

  describe 'with webarchive_seed' do
    let(:type) { Cocina::Models::Vocab.webarchive_seed }

    it { is_expected.to eq 'Process : Content Type : Webarchive Seed' }
  end
end
