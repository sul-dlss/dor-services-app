# frozen_string_literal: true

module Catalog
  # Service for retrieving MARC records from MARC dump files.
  # It builds a SQLite database from the MARC dump files, storing each record's MARC binary (zlib-compressed).
  class MarcDump
    class Error < StandardError; end
    class NotFound < Error; end

    # @param dump_filepath [String] the directory where the MARC dump files are located
    # @param db_filepath [String] the filepath where the MARC dump database should be created
    def initialize(dump_filepath: Settings.catalog.folio.refresh.dump_path,
                   db_filepath: Settings.catalog.folio.refresh.db_path)
      @dump_filepath = dump_filepath
      @db_filepath = db_filepath
    end

    # Build the MARC dump database by reading all the MARC records from the dump
    # and storing their HRID and zlib-compressed MARC binary in a SQLite database.
    # This may take 20+ minutes to run.
    def build_db! # rubocop:disable Metrics/AbcSize
      new_db = create_new_db!
      Dir.glob(File.join(dump_filepath, '*.mrc.gz')) do |filepath|
        filename = File.basename(filepath)
        Rails.logger.info("Processing file: #{filename}")
        Zlib::GzipReader.open(filepath, encoding: 'binary') do |gz|
          reader = MARC::ForgivingReader.new(gz, **reader_params)
          new_db.transaction do # Transaction speeds up inserts.
            reader.each do |record|
              new_db.execute 'insert into records values ( ?, ? )', [record['001'].value, Zlib::Deflate.deflate(record.to_marc)]
            end
          end
        end
      end
    end

    # @param hrid [String] the HRID of the record to find
    # @return [MARC::Record]
    # @raise Catalog::MarcDump::NotFound
    def find(hrid)
      row = db.execute('select data from records where hrid = ?', hrid).first
      raise NotFound, "Record not found for HRID: #{hrid}" unless row

      marc_binary = Zlib::Inflate.inflate(row[0])
      MARC::Reader.new(StringIO.new(marc_binary), **reader_params).first
    end

    private

    attr_reader :dump_filepath, :db_filepath

    def db
      @db ||= begin
        raise Error, 'Database must be built before finding records' unless File.exist?(db_filepath)

        SQLite3::Database.new(db_filepath, readonly: true)
      end
    end

    # @return [SQLite3::Database] a new SQLite database with the appropriate schema for storing MARC records
    def create_new_db!
      FileUtils.rm_f(db_filepath)
      SQLite3::Database.new(db_filepath).tap do |db|
        db.execute <<~SQL.squish
          create table records (
            hrid varchar(20) primary key,
            data blob not null
          );
        SQL
      end
    end

    def reader_params
      { invalid: :replace, replace: '', external_encoding: 'UTF-8' }
    end
  end
end
