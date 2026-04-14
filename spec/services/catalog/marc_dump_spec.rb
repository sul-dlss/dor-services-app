require 'rails_helper'

RSpec.describe Catalog::MarcDump do
  subject(:marc_dump) { described_class.new(dump_filepath: fixture_dir, db_filepath: db_path) }

  let(:fixture_dir) { 'spec/fixtures/marc_dump' }
  let(:db_path) { 'tmp/marc_dump_test.db' }
  let(:hrid) { 'in00000385419' }

  after do
    FileUtils.rm_f(db_path)
  end

  describe '#find' do
    it 'indexes and finds a MARC record by HRID' do
      marc_dump.build_db!

      record = marc_dump.find(hrid)
      expect(record).to be_a(MARC::Record)
      expect(record['001'].value).to eq(hrid)
    end

    it 'raises NotFound for missing HRID' do
      marc_dump.build_db!

      expect { marc_dump.find('notarealhrid') }.to raise_error(Catalog::MarcDump::NotFound)
    end

    it 'raises an error if the database has not been built' do
      expect do
        marc_dump.find(hrid)
      end.to raise_error(Catalog::MarcDump::Error, 'Database must be built before finding records')
    end
  end
end
