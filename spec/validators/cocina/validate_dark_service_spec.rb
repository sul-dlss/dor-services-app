# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::ValidateDarkService do
  let(:validator) { described_class.new(item) }

  let(:access) { 'dark' }
  let(:file_access) { 'dark' }
  let(:publish) { false }
  let(:shelve) { false }
  let(:mime_type) { 'text/plain' }

  let(:item) do
    Cocina::Models::DRO.new(
      externalIdentifier: 'druid:bc123df4567',
      label: 'The Structure of Scientific Revolutions',
      type: 'http://cocina.sul.stanford.edu/models/book.jsonld',
      version: 1,
      description: {
        title: [{ value: 'The Structure of Scientific Revolutions' }],
        purl: 'https://purl.stanford.edu/bc123df4567'
      },
      administrative: {
        hasAdminPolicy: 'druid:df123cd4567'
      },
      access: { access: access, download: 'none' },
      structural: {
        contains: [
          {
            externalIdentifier: 'bc123df4567_1',
            label: 'Fileset 1',
            type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
            version: 1,
            structural: {
              contains: [
                { externalIdentifier: 'bc123df4567_1',
                  label: 'Page 1',
                  type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                  version: 1,
                  access: { access: file_access, download: 'none' },
                  administrative: {
                    publish: publish,
                    shelve: shelve,
                    sdrPreserve: true
                  },
                  hasMessageDigests: [],
                  hasMimeType: mime_type,
                  filename: 'page1.txt' }
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

    context 'when not a WARC' do
      it 'is not valid' do
        expect(validator.valid?).to be false
        expect(validator.error).to eq 'Not all files have dark access and/or are unshelved when object access is dark: ["page1.txt"]'
      end
    end

    context 'when a WARC' do
      let(:mime_type) { 'application/warc' }

      it 'is valid' do
        expect(validator.valid?).to be true
      end
    end
  end

  context 'when dark and publish is true' do
    let(:publish) { true }

    it 'is valid' do
      expect(validator.valid?).to be true
    end
  end

  context 'with a non-DRO object' do
    let(:item) do
      Cocina::Models::Collection.new(
        externalIdentifier: 'druid:bc123df4567',
        label: 'The Structure of Scientific Revolutions',
        type: Cocina::Models::Vocab.collection,
        description: {
          title: [{ value: 'The Structure of Scientific Revolutions' }],
          purl: 'https://purl.stanford.edu/bc123df4567'
        },
        version: 1,
        access: { access: access }
      )
    end

    it 'is valid' do
      expect(validator.valid?).to be true
    end
  end
end
