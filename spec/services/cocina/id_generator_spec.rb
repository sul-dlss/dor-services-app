# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::IdGenerator do
  let(:bare_druid) { druid.delete_prefix('druid:') }
  let(:druid) { 'druid:bc123kj8759' }
  let(:uuid) { '123-234-975' }

  before do
    allow(SecureRandom).to receive(:uuid).and_return(uuid)
  end

  describe '.generate_or_existing_fileset_id' do
    subject(:file_set_id) { described_class.generate_or_existing_fileset_id(druid: druid, resource_id: resource_id) }

    context 'with a fully-qualified Cocina resource ID' do
      let(:resource_id) { "https://cocina.sul.stanford.edu/fileSet/#{bare_druid}/resource123" }

      it 'returns the ID with the druid-resource slash replaced with a hyphen' do
        expect(file_set_id).to eq("https://cocina.sul.stanford.edu/fileSet/#{bare_druid}-resource123")
      end
    end

    context 'with a nil resource ID' do
      let(:resource_id) { nil }

      it 'generates an ID with a UUID' do
        expect(file_set_id).to eq("https://cocina.sul.stanford.edu/fileSet/#{bare_druid}-#{uuid}")
      end
    end

    context 'with a non-standard Cocina URI resource ID' do
      let(:resource_id) { 'https://cocina.sul.stanford.edu/fileSet/resource123' }

      it 'generates an ID with the last segment picked off the ID' do
        expect(file_set_id).to eq("https://cocina.sul.stanford.edu/fileSet/#{bare_druid}-resource123")
      end
    end

    context 'with a non-standard string resource ID' do
      let(:resource_id) { 'resource123' }

      it 'generates an ID with the prior string' do
        expect(file_set_id).to eq("https://cocina.sul.stanford.edu/fileSet/#{bare_druid}-resource123")
      end
    end
  end

  describe '.generate_or_existing_file_id' do
    subject(:file_id) { described_class.generate_or_existing_file_id(druid: druid, resource_id: resource_id, file_id: given_file_id) }

    let(:given_file_id) { 'file123.txt' }

    context 'with a fully-qualified Cocina file ID' do
      let(:given_file_id) { "https://cocina.sul.stanford.edu/file/#{bare_druid}/resource123/file123.txt" }
      let(:resource_id) { nil }

      it 'returns the ID with the druid-resource slash replaced with a hyphen' do
        expect(file_id).to eq("https://cocina.sul.stanford.edu/file/#{bare_druid}-resource123/file123.txt")
      end
    end

    context 'with a nil resource ID' do
      let(:resource_id) { nil }

      it 'generates an ID with a UUID resource ID' do
        expect(file_id).to eq("https://cocina.sul.stanford.edu/file/#{bare_druid}-#{uuid}/#{given_file_id}")
      end
    end

    context 'with a non-standard Cocina URI resource ID' do
      let(:resource_id) { 'https://cocina.sul.stanford.edu/fileSet/resource123' }

      it 'generates an ID with the UUID picked off the resource ID' do
        expect(file_id).to eq("https://cocina.sul.stanford.edu/file/#{bare_druid}-resource123/#{given_file_id}")
      end
    end

    context 'with a non-standard string resource ID' do
      let(:resource_id) { 'resource123' }

      it 'generates an ID with the prior string' do
        expect(file_id).to eq("https://cocina.sul.stanford.edu/file/#{bare_druid}-resource123/#{given_file_id}")
      end
    end

    context 'with a nil file ID' do
      let(:given_file_id) { nil }
      let(:resource_id) { 'resource123' }

      it 'generates a file ID with a UUID' do
        expect(file_id).to eq("https://cocina.sul.stanford.edu/file/#{bare_druid}-resource123/#{uuid}")
      end
    end
  end
end
