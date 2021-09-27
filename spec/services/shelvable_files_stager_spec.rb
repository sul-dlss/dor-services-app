# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ShelvableFilesStager do
  subject(:stage) { described_class.stage(druid, content_metadata, shelve_diff, content_dir) }

  let(:workspace_root) { Dir.mktmpdir }
  let(:druid) { 'druid:jq937jp0017' }
  let(:content_metadata) { '<contentMetadata/>' }
  let(:workspace_druid) { DruidTools::Druid.new(druid, workspace_root) }

  # create an empty workspace location for object content files
  let(:content_dir) { Pathname(workspace_druid.path('content', true)) }

  # read in a FileInventoryDifference manifest from the fixtures area
  let(:content_diff_reports) { Pathname('spec').join('fixtures', 'content_diff_reports') }
  let(:inventory_diff_xml) { content_diff_reports.join('ng782rw8378-v3-v4.xml') }
  let(:inventory_diff) { Moab::FileInventoryDifference.parse(inventory_diff_xml.read) }
  let(:shelve_diff) { inventory_diff.group_difference('content') }

  context 'when the manifest files are not in the workspace' do
    let(:preservation_diff) { instance_double(Moab::FileInventoryDifference, group_difference: group_diff) }
    let(:group_diff) { instance_double(Moab::FileGroupDifference, file_deltas: file_deltas) }

    before do
      allow(Preservation::Client.objects).to receive(:content_inventory_diff).and_return(preservation_diff)
      # create the one modified file:
      FileUtils.touch(content_dir.join('SUB2_b2000_1.bvals'))
    end

    context 'when the file is not already in preservation' do
      let(:file_deltas) { { added: ['SUB2_b2000_2.bvecs', 'SUB2_b2000_2.nii.gz'] } }

      it 'raises an error' do
        expect { stage }.to raise_error('Unable to find SUB2_b2000_2.bvecs in the content directory')
      end
    end

    context 'when the file is in preservation' do
      let(:file_deltas) { { added: [] } }

      before do
        allow(Preservation::Client.objects).to receive(:content) do |*args|
          args.first.fetch(:on_data).call('my stuff')
        end
      end

      it 'copies the file into the staging area' do
        expect { stage }.to change { content_dir.join('SUB2_b2000_2.bvecs').exist? }.from(false).to(true)
      end
    end
  end

  context 'when the content files are in the workspace area' do
    before do
      # put the content files in the content_pathname location .../ng/782/rw/8378/ng782rw8378/content
      deltas = shelve_diff.file_deltas
      filelist = deltas[:modified] + deltas[:added] + deltas[:copyadded].collect { |_old, new| new }
      filelist.each { |file| FileUtils.touch(content_dir.join(file)) }
    end

    it { is_expected.to be true }
  end
end
