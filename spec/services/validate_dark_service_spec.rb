# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ValidateDarkService do
  let(:validator) { described_class.new(item) }

  let(:access) { 'dark' }
  # Note that publish = false when file > access > access = dark
  let(:file_access) { 'dark' }
  let(:shelve) { false }

  let(:item) do
    Cocina::Models::DRO.new(
      externalIdentifier: 'druid:bc123df4567',
      label: 'The Structure of Scientific Revolutions',
      type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
      version: 1,
      access: { access: access },
      structural: {
        contains: [
          {
            externalIdentifier: 'bc123df4567_1',
            label: 'Fileset 1',
            type: 'http://cocina.sul.stanford.edu/models/fileset.jsonld',
            version: 1,
            structural: {
              contains: [
                externalIdentifier: 'bc123df4567_1',
                label: 'Page 1',
                type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                version: 1,
                access: { access: file_access },
                administrative: {
                  shelve: shelve,
                  sdrPreserve: true
                },
                hasMessageDigests: [],
                filename: 'page1.txt'
              ]
            }
          }
        ]
      }
    )
  end

  context 'when dark and shelve and publish are false' do
    it 'is valid' do
      expect(validator.valid?).to be true
    end
  end

  context 'when not dark' do
    let(:access) { 'world' }

    it 'is valid' do
      expect(validator.valid?).to be true
    end
  end

  context 'when dark and shelve is true' do
    let(:shelve) { true }

    it 'is not valid' do
      expect(validator.valid?).to be false
      expect(validator.invalid_files.size).to eq(1)
      expect(validator.invalid_files.first.externalIdentifier).to eq('bc123df4567_1')
      expect(validator.invalid_filenames).to eq(['page1.txt'])
    end
  end

  context 'when dark and publish is true' do
    let(:file_access) { 'world' }

    it 'is not valid' do
      expect(validator.valid?).to be false
      expect(validator.invalid_files.size).to eq(1)
      expect(validator.invalid_files.first.externalIdentifier).to eq('bc123df4567_1')
    end
  end
end
