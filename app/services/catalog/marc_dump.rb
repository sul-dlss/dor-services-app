module Catalog
  # Service for retrieving MARC records from MARC dump files.
  # It builds a SQLite database from the MARC dump files that indexes the HRID, filename, and position of each record,
  # and allows for efficient lookup of a MARC record in the dump given an HRID.
  # The MARC dump files should be in the format of gzipped MARC files, where each file contains multiple MARC records.
  class MarcDump
    class Error < StandardError; end
    class NotFound < Error; end

    # @param dump_filepath [String] the directory where the MARC dump files are located
    # @param db_filepath [String] the filepath where the MARC dump database should be created
    def initialize(dump_filepath:, db_filepath: 'tmp/cache/marc_dump.db')
      @dump_filepath = dump_filepath
      @db_filepath = db_filepath
    end

    # Build the MARC dump database by reading all the MARC records from the dump
    # and storing their HRID, filename, and position in the file in a SQLite database.
    # This may take 20+ minutes to run.
    def build_db!
      new_db = create_new_db!
      Dir.glob(File.join(dump_filepath, '*.mrc.gz')) do |filepath|
        filename = File.basename(filepath)
        Rails.logger.info("Processing file: #{filename}")
        Zlib::GzipReader.open(filepath, encoding: 'binary') do |gz|
          reader = MARC::ForgivingReader.new(gz)
          new_db.transaction do # Transaction speeds up inserts.
            reader.each_with_index do |record, index|
              new_db.execute 'insert into records values ( ?, ?, ? )',
                             [record['001'].value.encode('UTF-8'), filename, index]
            end
          end
        end
      end
    end

    # @param hrid [String] the HRID of the record to find
    # @return [MARC::Record]
    # @raise Catalog::MarcDump::NotFound
    def find(hrid)
      row = db.execute('select filename, position from records where hrid = ?', hrid).first
      raise NotFound, "Record not found for HRID: #{hrid}" unless row

      filename, position = row
      filepath = File.join(dump_filepath, filename)
      Zlib::GzipReader.open(filepath, encoding: 'binary') do |gz|
        reader = MARC::ForgivingReader.new(gz)
        reader.each_with_index do |record, index|
          return record if index == position
        end
      end
      raise NotFound, "Record not found for HRID: #{hrid}"
    end

    private

    attr_reader :dump_filepath, :db_filepath

    def db
      @db ||= begin
        raise Error, 'Database must be built before finding records' unless File.exist?(db_filepath)

        SQLite3::Database.new(db_filepath)
      end
    end

    # @return [SQLite3::Database] a new SQLite database with the appropriate schema for storing MARC record metadata
    def create_new_db!
      FileUtils.rm_f(db_filepath)
      SQLite3::Database.new(db_filepath).tap do |db|
        db.execute <<~SQL.squish
          create table records (
            hrid varchar(20) primary key,
            filename varchar(30),
            position int
          );
        SQL
      end
    end
  end
end
