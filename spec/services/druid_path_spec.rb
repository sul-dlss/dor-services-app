# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DruidPath do
  let(:strictly_valid_druid_str) { 'druid:cd456gh1234' }
  let(:tree2) { File.join(fixture_dir, 'cd/456/gh/1234/cd456gh1234') }

  after do
    FileUtils.rm_rf(File.join(fixture_dir, 'cd'))
  end

  describe '#mkdir error handling' do
    it 'raises SameContentExistsError if the directory already exists' do
      druid_obj = DruidTools::Druid.new(strictly_valid_druid_str, fixture_dir)
      service = described_class.new(druid: druid_obj)
      service.mkdir
      expect { service.mkdir }.to raise_error(described_class::SameContentExistsError)
    end

    it 'raises DifferentContentExistsError if a link already exists in the workspace for this druid' do
      source_dir = '/tmp/content_dir'
      FileUtils.mkdir_p(source_dir)
      dr = DruidTools::Druid.new(strictly_valid_druid_str, fixture_dir)
      service = described_class.new(druid: dr)
      service.mkdir_with_final_link(source_dir)

      expect { service.mkdir }.to raise_error(described_class::DifferentContentExistsError)
    end
  end

  describe '#mkdir_with_final_link' do
    let(:source_dir) { '/tmp/content_dir' }
    let(:druid_obj) { DruidTools::Druid.new(strictly_valid_druid_str, fixture_dir) }
    let(:service) { described_class.new(druid: druid_obj) }

    before do
      FileUtils.mkdir_p(source_dir)
    end

    it 'creates a druid tree in the workspace with the final directory being a link to the passed in source' do
      service.mkdir_with_final_link(source_dir)
      expect(File).to be_symlink(druid_obj.path)
      expect(File.readlink(tree2)).to eq(source_dir)
    end

    it 'raises DifferentContentExistsError if a directory already exists in the workspace for this druid' do
      service.mkdir(fixture_dir)
      expect { service.mkdir_with_final_link(source_dir) }.to raise_error(described_class::DifferentContentExistsError)
    end
  end

  describe '#rmdir' do
    let(:druid_str) { 'druid:cd456ef7890' }
    let(:tree1) { File.join(fixture_dir, 'cd/456/ef/7890/cd456ef7890') }
    let(:druid1) { DruidTools::Druid.new(druid_str, fixture_dir) }
    let(:druid2) { DruidTools::Druid.new(strictly_valid_druid_str, fixture_dir) }
    let(:service1) { described_class.new(druid: druid1) }
    let(:service2) { described_class.new(druid: druid2) }

    it 'destroys druid directories' do
      expect(File.exist?(tree1)).to eq false
      expect(File.exist?(tree2)).to eq false

      service1.mkdir
      expect(File.exist?(tree1)).to eq true
      expect(File.exist?(tree2)).to eq false

      service2.mkdir
      expect(File.exist?(tree1)).to eq true
      expect(File.exist?(tree2)).to eq true

      service2.rmdir
      expect(File.exist?(tree1)).to eq true
      expect(File.exist?(tree2)).to eq false

      service1.rmdir
      expect(File.exist?(tree1)).to eq false
      expect(File.exist?(tree2)).to eq false
      expect(File.exist?(File.join(fixture_dir, 'cd'))).to eq false
    end
  end
end
