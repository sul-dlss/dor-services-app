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

  describe 'with book RTL' do
    let(:type) { Cocina::Models::Vocab.book }
    let(:direction) { 'right-to-left' }

    it { is_expected.to eq 'Process : Content Type : Book (rtl)' }
  end

  describe 'with book LTR' do
    let(:type) { Cocina::Models::Vocab.book }
    let(:direction) { 'left-to-right' }

    it { is_expected.to eq 'Process : Content Type : Book (ltr)' }
  end

  describe 'with agreement' do
    let(:type) { Cocina::Models::Vocab.agreement }

    it { is_expected.to be_nil }
  end

  describe 'with webarchive-binary' do
    let(:type) { Cocina::Models::Vocab.webarchive_binary }

    it { is_expected.to be_nil }
  end
end
