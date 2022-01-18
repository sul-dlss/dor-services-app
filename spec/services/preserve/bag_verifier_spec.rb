# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Preserve::BagVerifier do
  let(:fixtures) { Pathname(File.dirname(__FILE__)).join('../../fixtures') }

  describe '#verify_pathname' do
    subject(:verify_pathname) { instance.verify_pathname(path) }

    let(:instance) { described_class.new(directory: instance_double(Pathname)) }

    context 'with an existing directory' do
      let(:path) { fixtures.join('workspace/dd/116/zh/0343/dd116zh0343/metadata') }

      it { is_expected.to be true }
    end

    context 'with an existing file' do
      let(:path) { fixtures.join('workspace/dd/116/zh/0343/dd116zh0343/metadata/versionMetadata.xml') }

      it { is_expected.to be true }
    end

    context 'with a non-existent file' do
      let(:path) { fixtures.join('workspace/dd/116/zh/0343/dd116zh0343/metadata/badfile.xml') }

      it 'raises an exception' do
        expect { verify_pathname }.to raise_exception(/badfile.xml not found/)
      end
    end
  end
end
