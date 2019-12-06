# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvingService do
  let(:shelvable_item) do
    Dor::Item
  end

  let!(:stacks_root) { Dir.mktmpdir }
  let!(:workspace_root) { Dir.mktmpdir }

  before do
    allow(Dor::Config.stacks).to receive_messages(local_stacks_root: stacks_root, local_workspace_root: workspace_root)
  end

  after do
    FileUtils.remove_entry stacks_root
    FileUtils.remove_entry workspace_root
  end

  let(:work) { shelvable_item.new(pid: druid) }
  let(:service) { described_class.new work }

  describe '.shelve' do
    let(:druid) { 'druid:ng782rw8378' }
    let(:mock_diff) { double(Moab::FileGroupDifference) }
    let(:mock_workspace_path) { double(Pathname) }

    before do
      allow(described_class).to receive(:new).and_return(service)
      # stub the shelve_diff method which is unit tested below
      expect(service).to receive(:shelve_diff).and_return(mock_diff).at_least(:once)
      # stub the workspace_content_dir method which is unit tested below
      expect(service).to receive(:workspace_content_dir).with(mock_diff, an_instance_of(DruidTools::Druid)).and_return(mock_workspace_path)
    end

    it 'pushes file changes for shelve-able files into the stacks' do
      stacks_object_pathname = Pathname(DruidTools::StacksDruid.new(druid, stacks_root).path)
      # make sure the DigitalStacksService is getting the correct delete, rename, and shelve requests
      # (These methods are unit tested in digital_stacks_service_spec.rb)
      expect(DigitalStacksService).to receive(:remove_from_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to receive(:rename_in_stacks).with(stacks_object_pathname, mock_diff)
      expect(DigitalStacksService).to receive(:shelve_to_stacks).with(mock_workspace_path, stacks_object_pathname, mock_diff)
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

  describe '#workspace_content_dir' do
    subject { service.send(:workspace_content_dir, content_diff, workspace_druid) }

    let(:druid) { 'druid:jq937jp0017' }
    let(:workspace_druid) { DruidTools::Druid.new(druid, Dor::Config.stacks.local_workspace_root) }

    # create an empty workspace location for object content files
    let(:content_dir) { workspace_druid.path('content', true) }

    # read in a FileInventoryDifference manifest from the fixtures area
    let(:content_diff_reports) { Pathname('spec').join('fixtures', 'content_diff_reports') }
    let(:inventory_diff_xml) { content_diff_reports.join('ng782rw8378-v3-v4.xml') }
    let(:inventory_diff) { Moab::FileInventoryDifference.parse(inventory_diff_xml.read) }
    let(:content_diff) { inventory_diff.group_difference('content') }

    context 'when the manifest files are not in the workspace' do
      it 'raises an error' do
        expect { subject }.to raise_error(ShelvingService::ContentDirNotFoundError, /content dir not found/)
      end
    end

    context 'when the content files are in the workspace area' do
      before do
        # put the content files in the content_pathname location .../ng/782/rw/8378/ng782rw8378/content
        deltas = content_diff.file_deltas
        filelist = deltas[:modified] + deltas[:added] + deltas[:copyadded].collect { |_old, new| new }
        expect(filelist).to eq(['SUB2_b2000_2.bvecs', 'SUB2_b2000_2.nii.gz', 'SUB2_b2000_1.bvals'])
        filelist.each { |file| FileUtils.touch(File.join(content_dir, file)) }
      end

      it { is_expected.to eq Pathname(content_dir) }

      context 'when the content files are up a directory to .../ng/782/rw/8378/ng782rw8378' do
        let(:content_dir) { workspace_druid.path(nil, true) }

        it { is_expected.to eq Pathname(content_dir) }
      end

      context 'when the content files are up a dreictory to .../ng/782/rw/8378' do
        let(:content_dir) { Pathname(workspace_druid.path(nil, true)).parent }

        it { is_expected.to eq Pathname(content_dir) }
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
