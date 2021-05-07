# frozen_string_literal: true

require 'rails_helper'
require 'fileutils'

RSpec.describe SdrIngestService do
  let(:fixtures) { Pathname(File.dirname(__FILE__)).join('../fixtures') }
  let(:export_dir) { Pathname(Settings.sdr.local_export_home) }
  let(:fixture_sig_cat_obj) do
    Moab::SignatureCatalog.parse(
      File.open(fixtures.join('sdr_repo/dd116zh0343/v0001/manifests/signatureCatalog.xml')).read
    )
  end

  before do
    allow(Settings.sdr).to receive_messages(local_workspace_root: fixtures.join('workspace').to_s,
                                            local_export_home: fixtures.join('export').to_s)

    export_dir.rmtree if export_dir.exist? && export_dir.basename.to_s == 'export'
    export_dir.mkdir
  end

  after do
    export_dir.rmtree if export_dir.exist? && export_dir.basename.to_s == 'export'
  end

  it 'can access configuration settings' do
    sdr = Settings.sdr
    expect(sdr.local_workspace_root).to eq fixtures.join('workspace').to_s
    expect(sdr.local_export_home).to eq fixtures.join('export').to_s
  end

  it 'can find the fixtures workspace and export folders' do
    expect(File).to be_directory(Settings.sdr.local_workspace_root)
    expect(File).to be_directory(Settings.sdr.local_export_home)
  end

  describe '.transfer' do
    let(:druid) { 'druid:dd116zh0343' }
    let(:dor_item) { instance_double(Dor::Item, pid: druid) }
    let(:metadata_dir) { fixtures.join('workspace/dd/116/zh/0343/dd116zh0343/metadata') }

    before do
      allow(Preservation::Client.objects).to receive(:signature_catalog).and_return(fixture_sig_cat_obj)
      expect(DatastreamExtractor).to receive(:extract_datastreams).with(item: dor_item, workspace: an_instance_of(DruidTools::Druid)).and_return(metadata_dir)
    end

    specify 'with content changes' do
      described_class.transfer(dor_item)
      files = []
      fixtures.join('export/dd116zh0343').find { |f| files << f.relative_path_from(fixtures).to_s }
      expect(files.sort).to eq([
                                 'export/dd116zh0343',
                                 'export/dd116zh0343/bag-info.txt',
                                 'export/dd116zh0343/bagit.txt',
                                 'export/dd116zh0343/data',
                                 'export/dd116zh0343/data/content',
                                 'export/dd116zh0343/data/content/folder1PuSu',
                                 'export/dd116zh0343/data/content/folder1PuSu/story3m.txt',
                                 'export/dd116zh0343/data/content/folder1PuSu/story5a.txt',
                                 'export/dd116zh0343/data/content/folder3PaSd',
                                 'export/dd116zh0343/data/content/folder3PaSd/storyDm.txt',
                                 'export/dd116zh0343/data/content/folder3PaSd/storyFa.txt',
                                 'export/dd116zh0343/data/metadata',
                                 'export/dd116zh0343/data/metadata/contentMetadata.xml',
                                 'export/dd116zh0343/data/metadata/tech-generated.xml',
                                 'export/dd116zh0343/data/metadata/technicalMetadata-bad.xml',
                                 'export/dd116zh0343/data/metadata/technicalMetadata.xml',
                                 'export/dd116zh0343/data/metadata/versionMetadata.xml',
                                 'export/dd116zh0343/manifest-md5.txt',
                                 'export/dd116zh0343/manifest-sha1.txt',
                                 'export/dd116zh0343/manifest-sha256.txt',
                                 'export/dd116zh0343/tagmanifest-md5.txt',
                                 'export/dd116zh0343/tagmanifest-sha1.txt',
                                 'export/dd116zh0343/tagmanifest-sha256.txt',
                                 'export/dd116zh0343/versionAdditions.xml',
                                 'export/dd116zh0343/versionInventory.xml'
                               ])
    end

    specify 'with no change in content' do
      v1_content_metadata = fixtures.join('sdr_repo/dd116zh0343/v0001/data/metadata/contentMetadata.xml')
      expect(described_class).to receive(:get_content_metadata).with(metadata_dir).and_return(v1_content_metadata.read)
      described_class.transfer(dor_item)
      files = []
      fixtures.join('export/dd116zh0343').find { |f| files << f.relative_path_from(fixtures).to_s }
      expect(files.sort).to eq([
                                 'export/dd116zh0343',
                                 'export/dd116zh0343/bag-info.txt',
                                 'export/dd116zh0343/bagit.txt',
                                 'export/dd116zh0343/data',
                                 'export/dd116zh0343/data/metadata',
                                 'export/dd116zh0343/data/metadata/contentMetadata.xml',
                                 'export/dd116zh0343/data/metadata/tech-generated.xml',
                                 'export/dd116zh0343/data/metadata/technicalMetadata-bad.xml',
                                 'export/dd116zh0343/data/metadata/technicalMetadata.xml',
                                 'export/dd116zh0343/data/metadata/versionMetadata.xml',
                                 'export/dd116zh0343/manifest-md5.txt',
                                 'export/dd116zh0343/manifest-sha1.txt',
                                 'export/dd116zh0343/manifest-sha256.txt',
                                 'export/dd116zh0343/tagmanifest-md5.txt',
                                 'export/dd116zh0343/tagmanifest-sha1.txt',
                                 'export/dd116zh0343/tagmanifest-sha256.txt',
                                 'export/dd116zh0343/versionAdditions.xml',
                                 'export/dd116zh0343/versionInventory.xml'
                               ])
    end
  end

  describe '.signature_catalog_from_preservation' do
    let(:druid) { 'druid:dd116zh0343' }
    let(:dor_item) { instance_double(Dor::Item, pid: druid) }

    context 'when signature_catalog exists in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:signature_catalog).and_return(fixture_sig_cat_obj)
      end

      it 'retrieves it as a Moab::SignatureCatalog object' do
        sig_cat = described_class.signature_catalog_from_preservation(dor_item.pid)
        expect(sig_cat).to be_an_instance_of(Moab::SignatureCatalog)
        expect(sig_cat.digital_object_id).to eq dor_item.pid
        expect(sig_cat.version_id).to eq 1
        expect(sig_cat.entries.size).to eq 19
      end
    end

    context 'when signature_catalog does not exist in preservation' do
      before do
        allow(Preservation::Client.objects).to receive(:signature_catalog).and_raise(Preservation::Client::NotFoundError)
      end

      it 'returns a Moab::SignatureCatalog object for version 0' do
        sig_cat = described_class.signature_catalog_from_preservation(dor_item.pid)
        expect(sig_cat).to be_an_instance_of(Moab::SignatureCatalog)
        expect(sig_cat.digital_object_id).to eq dor_item.pid
        expect(sig_cat.version_id).to eq 0
        expect(sig_cat.entries).to eq []
      end
    end
  end

  specify '.get_version_inventory' do
    metadata_dir = instance_double(Pathname)
    druid = 'druid:ab123cd4567'
    version_id = 2
    version_inventory = Moab::FileInventory.new
    version_inventory.groups << Moab::FileGroup.new(group_id: 'content')
    metadata_group = Moab::FileGroup.new(group_id: 'metadata')
    expect(described_class).to receive(:get_content_inventory).with(metadata_dir, druid, version_id).and_return(version_inventory)
    expect(described_class).to receive(:get_metadata_file_group).with(metadata_dir).and_return(metadata_group)
    result = described_class.get_version_inventory(metadata_dir, druid, version_id)
    expect(result).to be_instance_of Moab::FileInventory
    expect(result.groups.size).to eq 2
  end

  specify '.get_content_inventory' do
    metadata_dir = fixtures.join('workspace/ab/123/cd/4567/ab123cd4567/metadata')
    druid = 'druid:ab123cd4567'
    version_id = 2

    version_inventory = described_class.get_content_inventory(metadata_dir, druid, version_id)
    expect(version_inventory).to be_instance_of Moab::FileInventory
    expect(version_inventory.version_id).to eq 2
    content_group = version_inventory.groups[0]
    expect(content_group.group_id).to eq 'content'
    expect(content_group.files.size).to eq 2
    # files in the 2nd resource are copied from the first resource
    expect(content_group.files[0].instances.size).to eq 2

    # if no content metadata
    metadata_dir = fixtures.join('workspace/ab/123/cd/4567/ab123cd4567')
    version_inventory = described_class.get_content_inventory(metadata_dir, druid, version_id)
    expect(version_inventory.groups.size).to eq 0
  end

  specify '.get_content_metadata' do
    metadata_dir = fixtures.join('workspace/ab/123/cd/4567/ab123cd4567/metadata')
    content_metadata = described_class.get_content_metadata(metadata_dir)
    expect(content_metadata).to match(/<contentMetadata /)

    # if no content metadata
    metadata_dir = fixtures.join('workspace/ab/123/cd/4567/ab123cd4567')
    content_metadata = described_class.get_content_metadata(metadata_dir)
    expect(content_metadata).to be_nil
  end

  specify '.get_metadata_file_group' do
    metadata_dir = instance_double(Pathname)
    file_group = instance_double(Moab::FileGroup)
    expect(Moab::FileGroup).to receive(:new).with(group_id: 'metadata').and_return(file_group)
    expect(file_group).to receive(:group_from_directory).with(metadata_dir)
    described_class.get_metadata_file_group(metadata_dir)
  end

  specify '.verify_version_id' do
    expect(described_class.verify_version_id('/mypath/myfile', 2, 2)).to be_truthy
    expect { described_class.verify_version_id('/mypath/myfile', 1, 2) }.to raise_exception('Version mismatch in /mypath/myfile, expected 1, found 2')
  end

  specify '.vmfile_version_id' do
    metadata_dir = fixtures.join('workspace/dd/116/zh/0343/dd116zh0343/metadata')
    vmfile = metadata_dir.join('versionMetadata.xml')
    expect(described_class.vmfile_version_id(vmfile)).to eq 2
  end

  specify '.verify_pathname' do
    metadata_dir = fixtures.join('workspace/dd/116/zh/0343/dd116zh0343/metadata')
    expect(described_class.verify_pathname(metadata_dir)).to be_truthy
    vmfile = metadata_dir.join('versionMetadata.xml')
    expect(described_class.verify_pathname(vmfile)).to be_truthy
    badfile = metadata_dir.join('badfile.xml')
    expect { described_class.verify_pathname(badfile) }.to raise_exception(/badfile.xml not found/)
  end
end
