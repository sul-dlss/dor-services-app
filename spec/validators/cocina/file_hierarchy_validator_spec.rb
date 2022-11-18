# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina::FileHierarchyValidator do
  let(:validator) { described_class.new(cocina_object) }
  let(:cocina_object) do
    instance_double(Cocina::Models::DRO, structural:, type:)
  end

  let(:structural) do
    Cocina::Models::DROStructural.new(
      { contains: [{ externalIdentifier: 'https://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                     type: Cocina::Models::FileSetType.file,
                     version: 1,
                     structural: { contains: [{ externalIdentifier: 'https://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                type: Cocina::Models::ObjectType.file,
                                                label: 'story1u.txt',
                                                filename:,
                                                size: 7888,
                                                version: 1,
                                                hasMessageDigests: [{ type: 'sha1',
                                                                      digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                    { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                access: { view: 'world', download: 'world' },
                                                administrative: { publish: true, sdrPreserve: false, shelve: true },
                                                hasMimeType: 'text/plain' }] },
                     label: 'Folder 1' }],
        isMemberOf: ['druid:bb077hj4590'] }
    )
  end

  context 'when hierarchy is present and content type is file' do
    let(:filename) { 'folder1PuSu/story1u.txt' }
    let(:type) { Cocina::Models::ObjectType.object }

    it 'is valid' do
      expect(validator.valid?).to be true
      expect(validator.error).to be_nil
    end
  end

  context 'when hierarchy is not present and content type is not file' do
    let(:filename) { 'story1u.txt' }
    let(:type) { Cocina::Models::ObjectType.book }

    it 'is valid' do
      expect(validator.valid?).to be true
      expect(validator.error).to be_nil
    end
  end

  context 'when hierarchy is present and content type is not file' do
    let(:filename) { 'folder1PuSu/story1u.txt' }
    let(:type) { Cocina::Models::ObjectType.book }

    it 'is invalid' do
      expect(validator.valid?).to be false
      expect(validator.error).to be 'File hierarchy present, but content type is not file'
    end
  end

  context 'when no structural' do
    let(:structural) { nil }
    let(:type) { Cocina::Models::ObjectType.object }

    it 'is valid' do
      expect(validator.valid?).to be true
      expect(validator.error).to be_nil
    end
  end
end
