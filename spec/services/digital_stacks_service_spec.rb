# frozen_string_literal: true

require 'rails_helper'
require 'moab/stanford'

RSpec.describe DigitalStacksService do
  before do
    @content_diff_reports = Pathname('spec').join('fixtures', 'content_diff_reports')

    inventory_diff_xml = @content_diff_reports.join('gj643zf5650-v3-v4.xml')
    inventory_diff = Moab::FileInventoryDifference.parse(inventory_diff_xml.read)
    @gj643zf5650_content_diff = inventory_diff.group_difference('content')

    inventory_diff_xml = @content_diff_reports.join('jq937jp0017-v1-v2.xml')
    inventory_diff = Moab::FileInventoryDifference.parse(inventory_diff_xml.read)
    @jq937jp0017_content_diff = inventory_diff.group_difference('content')

    inventory_diff_xml = @content_diff_reports.join('ng782rw8378-v3-v4.xml')
    inventory_diff = Moab::FileInventoryDifference.parse(inventory_diff_xml.read)
    @ng782rw8378_content_diff = inventory_diff.group_difference('content')
  end

  describe '.remove_from_stacks' do
    it 'deletes content from the digital stacks by druid and file names' do
      s = Pathname('/s')

      content_diff = @gj643zf5650_content_diff
      delete_list = get_delete_list(content_diff)
      expect(delete_list.map { |file| file[0, 2] }).to eq([[:deleted, 'page-3.jpg']])
      delete_list.each do |_change_type, filename, signature|
        expect(described_class).to receive(:delete_file).with(s.join(filename), signature)
      end
      described_class.remove_from_stacks(s, content_diff)

      content_diff = @jq937jp0017_content_diff
      delete_list = get_delete_list(content_diff)
      expect(delete_list.map { |file| file[0, 2] }).to eq([
                                                            [:deleted, 'intro-1.jpg'],
                                                            [:deleted, 'intro-2.jpg'],
                                                            [:modified, 'page-1.jpg']
                                                          ])
      delete_list.each do |_change_type, filename, signature|
        expect(described_class).to receive(:delete_file).with(s.join(filename), signature)
      end
      described_class.remove_from_stacks(s, content_diff)

      content_diff = @ng782rw8378_content_diff
      delete_list = get_delete_list(content_diff)
      expect(delete_list.map { |file| file[0, 2] }).to eq([
                                                            [:deleted, 'SUB2_b2000_1.bvecs'],
                                                            [:deleted, 'SUB2_b2000_1.bvals'],
                                                            [:deleted, 'SUB2_b2000_1.nii.gz']
                                                          ])
      delete_list.each do |_change_type, filename, signature|
        expect(described_class).to receive(:delete_file).with(s.join(filename), signature)
      end
      described_class.remove_from_stacks(s, content_diff)
    end
  end

  def get_delete_list(content_diff)
    delete_list = []
    %i[deleted copydeleted modified].each do |change_type|
      subset = content_diff.subset(change_type) # {Moab::FileGroupDifferenceSubset}
      subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
        moab_signature = moab_file.signatures.first # {Moab::FileSignature}
        delete_list << [change_type, moab_file.basis_path, moab_signature]
      end
    end
    delete_list
  end

  describe '.rename_in_stacks' do
    it 'renames content in the digital stacks' do
      s = Pathname('/s')

      content_diff = @gj643zf5650_content_diff
      rename_list = get_rename_list(content_diff)
      expect(rename_list.map { |file| file[0, 3] }).to eq([
                                                            [:renamed, 'page-2.jpg', 'page-2a.jpg'],
                                                            [:renamed, 'page-4.jpg', 'page-3.jpg']
                                                          ])
      rename_list.each do |_change_type, oldname, newname, signature|
        tempname = signature.checksums.values.last
        expect(described_class).to receive(:rename_file).with(s.join(oldname), s.join(tempname), signature)
        expect(described_class).to receive(:rename_file).with(s.join(tempname), s.join(newname), signature)
      end
      described_class.rename_in_stacks(s, content_diff)

      content_diff = @jq937jp0017_content_diff
      rename_list = get_rename_list(content_diff)
      expect(rename_list.map { |file| file[0, 3] }).to eq([])
      expect { described_class.rename_in_stacks(s, content_diff) }.not_to raise_error

      content_diff = @ng782rw8378_content_diff
      rename_list = get_rename_list(content_diff)
      expect(rename_list.map { |file| file[0, 3] }).to eq([
                                                            [:renamed, 'SUB2_b2000_2.nii.gz', 'SUB2_b2000_1.nii.gz'],
                                                            [:renamed, 'dir/SUB2_b2000_2.bvecs', 'SUB2_b2000_1.bvecs']
                                                          ])
      rename_list.each do |_change_type, oldname, newname, signature|
        tempname = signature.checksums.values.last
        expect(described_class).to receive(:rename_file).with(s.join(oldname), s.join(tempname), signature)
        expect(described_class).to receive(:rename_file).with(s.join(tempname), s.join(newname), signature)
      end
      described_class.rename_in_stacks(s, content_diff)
    end
  end

  def get_rename_list(content_diff)
    rename_list = []
    subset = content_diff.subset(:renamed) # {Moab::FileGroupDifferenceSubset
    subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
      moab_signature = moab_file.signatures.last # {Moab::FileSignature}
      rename_list << [:renamed, moab_file.basis_path, moab_file.other_path, moab_signature]
    end
    rename_list
  end

  describe '.shelve_to_stacks' do
    it 'copies the content to the digital stacks' do
      w = Pathname('/w')
      s = Pathname('/s')

      content_diff = @gj643zf5650_content_diff
      shelve_list = get_shelve_list(content_diff)
      expect(shelve_list.map { |file| file[0, 2] }).to eq([[:added, 'page-4.jpg']])
      shelve_list.each do |_change_type, filename, signature|
        expect(described_class).to receive(:copy_file).with(w.join(filename), s.join(filename), signature)
      end
      described_class.shelve_to_stacks(w, s, content_diff)

      content_diff = @jq937jp0017_content_diff
      shelve_list = get_shelve_list(content_diff)
      expect(shelve_list.map { |file| file[0, 2] }).to eq([[:modified, 'page-1.jpg']])
      shelve_list.each do |_change_type, filename, signature|
        expect(described_class).to receive(:copy_file).with(w.join(filename), s.join(filename), signature)
      end
      described_class.shelve_to_stacks(w, s, content_diff)

      content_diff = @ng782rw8378_content_diff
      shelve_list = get_shelve_list(content_diff)
      expect(shelve_list.map { |file| file[0, 2] }).to eq([
                                                            [:added, 'dir/SUB2_b2000_2.bvecs'],
                                                            [:added, 'SUB2_b2000_2.nii.gz'],
                                                            [:copyadded, 'SUB2_b2000_1.bvals']
                                                          ])
      shelve_list.each do |_change_type, filename, signature|
        expect(described_class).to receive(:copy_file).with(w.join(filename), s.join(filename), signature)
      end
      described_class.shelve_to_stacks(w, s, content_diff)
    end
  end

  def get_shelve_list(content_diff)
    shelve_list = []
    %i[added copyadded modified].each do |change_type|
      subset = content_diff.subset(change_type) # {Moab::FileGroupDifferenceSubset
      subset.files.each do |moab_file| # {Moab::FileInstanceDifference}
        moab_signature = moab_file.signatures.last # {Moab::FileSignature}
        filename = change_type == :modified ? moab_file.basis_path : moab_file.other_path
        shelve_list << [change_type, filename, moab_signature]
      end
    end
    shelve_list
  end

  context 'file operations' do
    before(:all) do
      @tmpdir = Pathname(Dir.mktmpdir('stacks'))
    end

    after(:all) do
      @tmpdir.rmtree if @tmpdir.exist?
    end

    describe '.delete_file' do
      it 'deletes a file, but only if it exists and matches the expected signature' do
        # if file does not exist
        file_pathname = @tmpdir.join('delete-me.txt')
        moab_signature = Moab::FileSignature.new
        expect(file_pathname).not_to exist
        expect(described_class.delete_file(file_pathname, moab_signature)).to be_falsey
        # if file exists, but has unexpected signature
        FileUtils.touch(file_pathname.to_s)
        expect(file_pathname).to exist
        expect(described_class.delete_file(file_pathname, moab_signature)).to be_falsey
        expect(file_pathname).to exist
        # if file exists, and has expected signature
        moab_signature = Moab::FileSignature.new.signature_from_file(file_pathname)
        # when run in a non-spec context, the moab_signature size is actually a string.
        moab_signature.size = moab_signature.size.to_s
        expect(described_class.delete_file(file_pathname, moab_signature)).to be_truthy
        expect(file_pathname).not_to exist
      end
    end

    describe '.rename_file' do
      it 'renames a file, but only if it exists and has the expected signature' do
        # if file does not exist
        old_pathname = @tmpdir.join('rename-me.txt')
        new_pathname = @tmpdir.join('new-name.txt')
        moab_signature = Moab::FileSignature.new
        expect(old_pathname).not_to exist
        expect(new_pathname).not_to exist
        expect(described_class.rename_file(old_pathname, new_pathname, moab_signature)).to be_falsey
        # if file exists, but has unexpected signature
        FileUtils.touch(old_pathname.to_s)
        expect(old_pathname).to exist
        expect(described_class.rename_file(old_pathname, new_pathname, moab_signature)).to be_falsey
        expect(old_pathname).to exist
        expect(new_pathname).not_to exist
        # if file exists, and has expected signature
        moab_signature = Moab::FileSignature.new.signature_from_file(old_pathname)
        expect(described_class.rename_file(old_pathname, new_pathname, moab_signature)).to be_truthy
        expect(old_pathname).not_to exist
        expect(new_pathname).to exist
      end
    end

    describe '.copy_file' do
      it 'copies a file to stacks, but only if it does not yet exist with the expected signature' do
        # if file does not exist in stacks
        workspace_pathname = @tmpdir.join('copy-me.txt')
        stacks_pathname = @tmpdir.join('stacks-name.txt')
        FileUtils.touch(workspace_pathname.to_s)
        FileUtils.chmod 0o640, workspace_pathname.to_s
        expect(File::Stat.new(workspace_pathname.to_s).mode.to_fs(8)).to eq('100640')
        moab_signature = Moab::FileSignature.new.signature_from_file(workspace_pathname)
        expect(workspace_pathname).to exist
        expect(stacks_pathname).not_to exist
        expect(described_class.copy_file(workspace_pathname, stacks_pathname, moab_signature)).to be_truthy
        # if file exists, and has expected signature
        expect(workspace_pathname).to exist
        expect(stacks_pathname).to exist
        expect(File::Stat.new(stacks_pathname.to_s).mode.to_fs(8)).to eq('100644')
        moab_signature = Moab::FileSignature.new.signature_from_file(stacks_pathname)
        expect(described_class.copy_file(workspace_pathname, stacks_pathname, moab_signature)).to be_falsey
        # if file exists, but has unexpected signature
        moab_signature = Moab::FileSignature.new
        expect(workspace_pathname).to exist
        expect(stacks_pathname).to exist
        expect(described_class.copy_file(workspace_pathname, stacks_pathname, moab_signature)).to be_truthy
      end
    end
  end
end
