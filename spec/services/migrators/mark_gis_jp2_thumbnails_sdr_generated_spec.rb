# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Migrators::MarkGisJp2ThumbnailsSdrGenerated do
  def cocina_file(filename, mimetype, use:, preserve:, sdr_generated: false)
    {
      'type' => Cocina::Models::ObjectType.file,
      'externalIdentifier' => "https://cocina.sul.stanford.edu/file/#{SecureRandom.uuid}",
      'label' => filename,
      'filename' => filename,
      'size' => 1,
      'version' => 1,
      'hasMimeType' => mimetype,
      'use' => use,
      'sdrGeneratedText' => sdr_generated,
      'hasMessageDigests' => [],
      'access' => { 'view' => 'world', 'download' => 'world' },
      'administrative' => { 'publish' => true, 'sdrPreserve' => preserve, 'shelve' => true }
    }
  end

  def file_set(label, files)
    {
      'type' => Cocina::Models::FileSetType.object,
      'externalIdentifier' => "https://cocina.sul.stanford.edu/fileSet/#{SecureRandom.uuid}",
      'label' => label,
      'version' => 1,
      'structural' => { 'contains' => files }
    }
  end

  def raster_file_set(jp2: robot_jp2)
    file_set('Object', [
               cocina_file('WesternAddition2.tif', geotiff, use: 'master', preserve: true),
               cocina_file('WesternAddition2.tif.xml', 'application/xml', use: 'master', preserve: true),
               cocina_file('WesternAddition2_cog.tif', "#{geotiff}; profile=cloud-optimized",
                           use: 'derivative', preserve: false, sdr_generated: true),
               jp2
             ])
  end

  def thumbnail_flags(hash)
    hash.dig('structural', 'contains').flat_map { |fs| fs.dig('structural', 'contains') }
        .select { |file| file['hasMimeType'] == 'image/jp2' }
        .map { |file| file['sdrGeneratedText'] }
  end

  let(:geotiff) { 'image/tiff; application=geotiff' }
  let(:robot_jp2) { cocina_file('WesternAddition2.jp2', 'image/jp2', use: 'thumbnail', preserve: false) }
  let(:file_sets) { [raster_file_set] }
  let(:type) { Cocina::Models::ObjectType.geo }
  let(:head_version) { true }
  let(:model_hash) do
    build(:dro, type:).to_h.deep_stringify_keys
                      .merge('access' => { 'view' => 'world', 'download' => 'world' },
                             'structural' => { 'contains' => file_sets }).freeze
  end

  describe '#migrate' do
    subject(:migrated) do
      described_class.new(model_hash: model_hash.deep_dup, valid: true, opened_version: false,
                          last_closed_version: head_version, head_version:).migrate
    end

    it 'marks a raster thumbnail named after its source as SDR generated' do
      expect(thumbnail_flags(migrated)).to eq [true]
    end

    it 'changes nothing else' do
      expected = model_hash.deep_dup
      expected.dig('structural', 'contains', 0, 'structural', 'contains', 3)['sdrGeneratedText'] = true
      expect(migrated).to eq expected
    end

    it 'produces valid cocina' do
      expect { Cocina::Models.build(migrated) }.not_to raise_error
    end

    context 'with a vector thumbnail' do
      let(:file_sets) do
        [file_set('Data', [
                    cocina_file('rail.shp', 'application/vnd.shp', use: nil, preserve: true),
                    cocina_file('rail.dbf', 'application/vnd.dbf', use: nil, preserve: true),
                    cocina_file('rail.jp2', 'image/jp2', use: 'thumbnail', preserve: false)
                  ])]
      end

      it 'marks it as SDR generated' do
        expect(thumbnail_flags(migrated)).to eq [true]
      end
    end

    context 'when the thumbnail is already marked SDR generated' do
      let(:robot_jp2) do
        cocina_file('WesternAddition2.jp2', 'image/jp2', use: 'thumbnail', preserve: false, sdr_generated: true)
      end

      it 'leaves the object unchanged' do
        expect(migrated).to eq model_hash
      end
    end

    context 'when it is not the head version' do
      let(:head_version) { false }

      it 'leaves the version as it was preserved' do
        expect(migrated).to eq model_hash
      end
    end

    context 'when the object is not geo' do
      let(:type) { Cocina::Models::ObjectType.image }

      it 'leaves the object unchanged' do
        expect(migrated).to eq model_hash
      end
    end

    context 'when the thumbnail is preserved' do
      let(:robot_jp2) { cocina_file('WesternAddition2.jp2', 'image/jp2', use: 'thumbnail', preserve: true) }

      it 'leaves it alone as the depositor\'s' do
        expect(migrated).to eq model_hash
      end
    end

    context 'when the thumbnail is not named after a source file' do
      let(:robot_jp2) { cocina_file('cover.jp2', 'image/jp2', use: 'thumbnail', preserve: false) }

      it 'leaves it alone' do
        expect(migrated).to eq model_hash
      end
    end

    context 'when the thumbnail is in a different file set from its source' do
      let(:file_sets) do
        [raster_file_set(jp2: cocina_file('readme.txt', 'text/plain', use: nil, preserve: true)),
         file_set('Preview', [robot_jp2])]
      end

      it 'leaves it alone' do
        expect(migrated).to eq model_hash
      end
    end

    context 'when the JP2 is not a thumbnail' do
      let(:robot_jp2) { cocina_file('WesternAddition2.jp2', 'image/jp2', use: nil, preserve: false) }

      it 'leaves it alone' do
        expect(migrated).to eq model_hash
      end
    end
  end

  describe '.migration_strategy' do
    it 'commits in place without versioning or publishing' do
      expect(described_class.migration_strategy).to eq :commit
      expect(described_class.version?).to be false
      expect(described_class.publish?).to be false
    end
  end

  describe 'running the migration' do
    let(:repository_object) do
      create(:repository_object, :with_repository_object_version).tap do |repository_object|
        set_structural!(repository_object.head_version)
        repository_object.close_version!(description: 'first version')
        repository_object.open_version!(description: 'second version')
        repository_object.close_version!
      end
    end

    def set_structural!(repository_object_version)
      repository_object_version.update!(content_type: type, structural: { 'contains' => file_sets })
    end

    def flags_for(version)
      thumbnail_flags(repository_object.versions.find_by(version:).to_h.deep_stringify_keys)
    end

    before do
      allow(Publish::MetadataTransferService).to receive(:publish)
    end

    it 'marks the thumbnail in the head version only, without versioning or publishing' do
      results = Migrators::MigrationRunner.new(migrator_class: described_class, repository_object:,
                                               mode: :migrate).call
      expect(results.map(&:to_h)).to contain_exactly(include(status: 'MIGRATED', version: 2))
      expect(flags_for(1)).to eq [false]
      expect(flags_for(2)).to eq [true]
      expect(repository_object.reload.head_version.version).to eq 2
      expect(repository_object).to be_closed
      expect(Publish::MetadataTransferService).not_to have_received(:publish)
    end
  end
end
