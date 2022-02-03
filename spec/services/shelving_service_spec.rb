# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvingService do
  let(:druid) { 'druid:ng782rw8378' }

  let(:cocina_object) do
    instance_double(Cocina::Models::DRO, externalIdentifier: druid, structural: structural, type: Cocina::Models::Vocab.book)
  end

  let(:structural) do
    Cocina::Models::DROStructural.new(
      { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/fileSet/8d17c28b-5b3e-477e-912c-f168a1f4213f',
                     type: 'http://cocina.sul.stanford.edu/models/resources/file.jsonld',
                     version: 1,
                     structural: { contains: [{ externalIdentifier: 'http://cocina.sul.stanford.edu/file/be451fd9-7908-4559-9e81-8d6f496a3181',
                                                type: 'http://cocina.sul.stanford.edu/models/file.jsonld',
                                                label: 'folder1PuSu/story1u.txt',
                                                filename: 'folder1PuSu/story1u.txt',
                                                size: 7888,
                                                version: 1,
                                                hasMessageDigests: [{ type: 'sha1',
                                                                      digest: '61dfac472b7904e1413e0cbf4de432bda2a97627' },
                                                                    { type: 'md5', digest: 'e2837b9f02e0b0b76f526eeb81c7aa7b' }],
                                                access: { access: 'world', download: 'world' },
                                                administrative: { publish: true, sdrPreserve: false, shelve: true },
                                                hasMimeType: 'text/plain' }] },
                     label: 'Folder 1' }],
        isMemberOf: collections }
    )
  end

  let(:collections) { ['druid:bb077hj4590'] }

  let(:content_metadata) do
    <<~XML
      <contentMetadata type="book" objectId="#{druid}">
        <resource sequence="1" type="file" id="folder1PuSu">
          <label>Folder 1</label>
          <file mimetype="text/plain" shelve="yes" publish="yes" size="7888" preserve="no" id="folder1PuSu/story1u.txt">
            <checksum type="md5">e2837b9f02e0b0b76f526eeb81c7aa7b</checksum>
            <checksum type="sha1">61dfac472b7904e1413e0cbf4de432bda2a97627</checksum>
          </file>
        </resource>
      </contentMetadata>
    XML
  end

  let(:stacks_root) { Dir.mktmpdir }
  let(:workspace_root) { Dir.mktmpdir }
  let(:mock_diff) { instance_double(Moab::FileGroupDifference) }
  let(:workflow_client) { instance_double(Dor::Workflow::Client, workflows: workflows) }
  let(:workflows) { ['accessionWF', 'registrationWF'] }
  let(:stacks_object_pathname) { Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path) }

  before do
    allow(WorkflowClientFactory).to receive(:build).and_return(workflow_client)
    allow(Dor::Config.stacks).to receive_messages(local_stacks_root: stacks_root, local_workspace_root: workspace_root)
    allow(Cocina::ToFedora::ContentMetadataGenerator).to receive(:generate).and_return(content_metadata)
    allow(Preservation::Client.objects).to receive(:shelve_content_diff).and_return(mock_diff)
    allow(ShelvableFilesStager).to receive(:stage)
    allow(DigitalStacksService).to receive(:remove_from_stacks)
    allow(DigitalStacksService).to receive(:rename_in_stacks)
    allow(DigitalStacksService).to receive(:shelve_to_stacks)
  end

  after do
    FileUtils.remove_entry stacks_root
    FileUtils.remove_entry workspace_root
  end

  context 'when structural present' do
    it 'pushes file changes for shelve-able files into the stacks' do
      stacks_object_pathname = Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path)
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      described_class.shelve(cocina_object)
      expect(ShelvableFilesStager).to have_received(:stage).with(druid, content_metadata, mock_diff, Pathname)
      expect(DigitalStacksService).to have_received(:remove_from_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to have_received(:rename_in_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to have_received(:shelve_to_stacks).with(Pathname, stacks_object_pathname, mock_diff)
      expect(Cocina::ToFedora::ContentMetadataGenerator).to have_received(:generate).with(druid: druid, structural: structural, type: Cocina::Models::Vocab.book)
    end
  end

  context 'when structural absent' do
    let(:structural) { nil }

    it 'raises' do
      expect { described_class.shelve(cocina_object) }.to raise_error(Dor::Exception)
    end
  end

  context 'when a web archive' do
    let(:workflows) { %w[accessionWF registrationWF wasCrawlPreassemblyWF] }
    let(:stacks_object_pathname) { Pathname('/web-archiving-stacks/data/collections/bb077hj4590/ng/782/rw/8378') }

    it 'pushes file changes for shelve-able files into the stacks' do
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      described_class.shelve(cocina_object)
      expect(ShelvableFilesStager).to have_received(:stage).with(druid, content_metadata, mock_diff, Pathname)
      expect(DigitalStacksService).to have_received(:remove_from_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to have_received(:rename_in_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to have_received(:shelve_to_stacks).with(Pathname, stacks_object_pathname, mock_diff)
      expect(Cocina::ToFedora::ContentMetadataGenerator).to have_received(:generate).with(druid: druid, structural: structural, type: Cocina::Models::Vocab.book)
    end
  end

  context 'when a web archive without collection' do
    let(:workflows) { %w[accessionWF registrationWF wasCrawlPreassemblyWF] }
    let(:collections) { [] }

    it 'raises' do
      expect { described_class.shelve(cocina_object) }.to raise_error(Dor::Exception)
    end
  end
end
