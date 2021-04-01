# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FromFedora::FileSets do
  describe '.resource_type' do
    subject { described_class.resource_type(node, ignore_resource_type_errors: false) }

    let(:node) { Nokogiri::XML::DocumentFragment.parse("<resource type=\"#{type}\" />").at_css('resource') }

    context 'when type is main-augmented (ETDs)' do
      let(:type) { 'main-augmented' }

      it { is_expected.to eq 'http://cocina.sul.stanford.edu/models/resources/main-augmented.jsonld' }
    end

    context 'when type is 3d' do
      let(:type) { '3d' }

      it { is_expected.to eq 'http://cocina.sul.stanford.edu/models/resources/3d.jsonld' }
    end

    context 'when the resource type is invalid' do
      let(:type) { 'bogus' }

      before { allow(Honeybadger).to receive(:notify) }

      context 'when ignore_resource_type_errors is not set' do
        it 'notifies Honeybadger' do
          described_class.resource_type(node, ignore_resource_type_errors: false)
          expect(Honeybadger).to have_received(:notify)
        end
      end

      context 'when ignore_resource_type_errors is set' do
        it 'does not notify Honeybadger' do
          described_class.resource_type(node, ignore_resource_type_errors: true)
          expect(Honeybadger).not_to have_received(:notify)
        end
      end
    end
  end
end
