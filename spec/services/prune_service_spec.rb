# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PruneService do
  let(:druid_str) { 'druid:cd456ef7890' }
  let(:strictly_valid_druid_str) { 'druid:cd456gh1234' }
  let(:access_druid_str) { 'druid:cd456ef9999' }

  describe '#prune!' do
    let(:workspace) { Dir.mktmpdir }
    let(:dr1) { DruidTools::Druid.new(druid_str, workspace) }
    let(:dr2) { DruidTools::Druid.new(strictly_valid_druid_str, workspace) }

    after do
      FileUtils.remove_entry workspace
    end

    context 'with an access druid sharing the first three path segments' do
      let(:dr3) { DruidTools::StacksDruid.new(access_druid_str, workspace) }

      before do
        # Nil the create records for this context because we're in a known read only one
        dr1.mkdir
        dr2.mkdir
        dr3.mkdir
        described_class.new(druid: dr3).prune!
      end

      it 'deletes the outermost directory' do
        expect(File).not_to exist(dr3.pruning_base)
      end

      it 'does not delete unrelated ancestor directories' do
        expect(File).to exist(dr1.pruning_base)
        expect(File).to exist(dr1.pruning_base.parent)
      end

      it 'stops at ancestor directories that have children' do
        # 'cd/456/ef' should still exist because of dr1
        shared_ancestor = dr1.pruning_base.parent
        expect(shared_ancestor.to_s).to match(%r{cd/456/ef$})
        expect(File).to exist(shared_ancestor)
      end
    end

    context 'when there is a shared ancestor' do
      let(:pathname1) { dr1.pathname }

      before do
        # Nil the create records for this context because we're in a known read only one
        dr1.mkdir
        dr2.mkdir
        described_class.new(druid: dr1).prune!
      end

      it 'deletes the outermost directory' do
        expect(File).not_to exist(dr1.path)
      end

      it 'deletes empty ancestor directories' do
        expect(File).not_to exist(pathname1.parent)
        expect(File).not_to exist(pathname1.parent.parent)
      end

      it 'stops at ancestor directories that have children' do
        # 'cd/456' should still exist because of druid2
        shared_ancestor = pathname1.parent.parent.parent
        expect(shared_ancestor.to_s).to match(%r{cd/456$})
        expect(File).to exist(shared_ancestor)
      end
    end

    it 'removes all directories up to the base path when there are no common ancestors' do
      # Nil the create records for this test
      dr1.mkdir
      described_class.new(druid: dr1).prune!
      expect(File).not_to exist(File.join(workspace, 'cd'))
      expect(File).to exist(workspace)
    end

    it 'removes directories with symlinks' do
      # Nil the create records for this test
      source_dir = File.join workspace, 'src_dir'
      FileUtils.mkdir_p(source_dir)
      WorkspaceService.send(:mkdir_with_final_link, druid: dr2, source: source_dir)

      described_class.new(druid: dr2).prune!

      expect(File).not_to exist(dr2.path)
      expect(File).not_to exist(File.join(workspace, 'cd'))
    end
  end
end
