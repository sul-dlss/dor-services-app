# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvingService do
  let(:service) { described_class.new(work) }

  let(:shelvable_item) do
    Dor::Item
  end

  let(:stacks_root) { Dir.mktmpdir }
  let(:workspace_root) { Dir.mktmpdir }

  before do
    allow(Dor::Config.stacks).to receive_messages(local_stacks_root: stacks_root, local_workspace_root: workspace_root)
  end

  after do
    FileUtils.remove_entry stacks_root
    FileUtils.remove_entry workspace_root
  end

  let(:work) { shelvable_item.new(pid: druid) }

  describe '.shelve' do
    let(:druid) { 'druid:ng782rw8378' }
    let(:mock_diff) { instance_double(Moab::FileGroupDifference) }

    before do
      allow(described_class).to receive(:new).and_return(service)
      # stub the shelve_diff method which is unit tested below
      allow(Preservation::Client.objects).to receive(:shelve_content_diff).and_return(mock_diff)
      allow(ShelvableFilesStager).to receive(:stage).with(druid, work.contentMetadata.content, mock_diff, Pathname)
    end

    it 'pushes file changes for shelve-able files into the stacks' do
      stacks_object_pathname = Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path)
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      expect(DigitalStacksService).to receive(:remove_from_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to receive(:rename_in_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to receive(:shelve_to_stacks).with(Pathname, stacks_object_pathname, mock_diff)
      described_class.shelve(work)
    end
  end

  describe '#shelve_diff' do
    subject(:result) { service.send(:shelve_diff) }

    let(:druid) { 'druid:jq937jp0017' }

    context 'when contentMetadata exists' do
      before do
        allow(Preservation::Client.objects).to receive(:shelve_content_diff)
      end

      it 'retrieves the differences between the current contentMetadata and preservation via preservation-client gem' do
        service.send(:shelve_diff)
        expect(Preservation::Client.objects).to have_received(:shelve_content_diff).with(druid: druid, content_metadata: work.contentMetadata.content)
      end
    end

    context 'when contentMetadata does not exist' do
      it 'raises an error' do
        work.datastreams.delete 'contentMetadata'
        expect { result }.to raise_error(Dor::Exception)
      end
    end
  end

  describe '#stacks_location' do
    subject(:location) { service.send(:stacks_location) }

    let(:druid) { 'druid:xy123xy1234' }

    it 'returns the default stack' do
      work.contentMetadata.content = '<contentMetadata/>'
      expect(location).to eq stacks_root
    end

    it 'returns the absolute stack' do
      work.contentMetadata.content = '<contentMetadata stacks="/specialstacks"/>'
      expect(location).to eq '/specialstacks'
    end

    it 'returns a relative stack' do
      work.contentMetadata.content = '<contentMetadata stacks="specialstacks"/>'
      expect { location }.to raise_error(RuntimeError)
    end
  end
end
