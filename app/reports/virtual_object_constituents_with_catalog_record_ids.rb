# frozen_string_literal: true

# Find items that have catalogRecordIds and that are also constituents of a parent virtual object

# Invoke like so (dumps to a datestamped CSV):
#  bin/rails r -e production "VirtualObjectConstituentsWithcatalogRecordIds.report(limit: 'ALL')" > constituent_druids_with_catalog_record_ids_`date --iso-8601=minutes`.csv
# To get a report of all parent druids for all constituent druids, you can do like so (also dumps to datestamped CSV):
#  bin/rails r -e production "puts VirtualObjectConstituentsWithCatalogRecordIdss.report(limit: 'ALL', print_catalog_record_id_report_to_stdout: false).parent_report_csv" > constituent_druids_parents_`date --iso-8601=minutes`.csv
# @note: if you use 'ALL' as the limit, this will iterate over all objects in SDR, and so may take a while (45ish minutes?) to run.
class VirtualObjectConstituentsWithCatalogRecordIds
  MEMBER_ORDERS_JSON_PATH = '$.hasMemberOrders[*].members[*]'

  attr_accessor :limit, :member_orders_by_druid, :constituent_info

  def initialize(limit:)
    @limit = limit
  end

  # @param limit [String] value for the SQL query's LIMIT clause, defaults to a useful test run value
  # @param print_catalog_record_id_report_to_stdout [boolean] default to dumping the CSV report of the constituents with CatalogRecordIds to stdout
  # @return [VirtualObjectConstituentsWithCatalogRecordIds] the new reporter instance; allows e.g.
  #   `reporter = VirtualObjectConstituentsWithCatalogRecordIds.report(limit: 'ALL', false)` if you're running
  #   from console and want to look at the results objects more closely, instead of just dumping a CSV
  def self.report(limit: '1', print_catalog_record_id_report_to_stdout: true)
    new(limit:).tap do |reporter|
      reporter.fetch_constituent_catalog_record_ids
      puts reporter.catalog_record_id_report_csv if print_catalog_record_id_report_to_stdout
    end
  end

  def self.constituent_druid_sql(limit:)
    <<~SQL.squish.freeze
      SELECT external_identifier vobj_external_identifier,
        JSONB_PATH_QUERY_ARRAY(structural, '#{MEMBER_ORDERS_JSON_PATH}') constituent_druids,
        JSONB_ARRAY_LENGTH(JSONB_PATH_QUERY_ARRAY(structural, '#{MEMBER_ORDERS_JSON_PATH}')) constituent_druids_count
      FROM dros
      WHERE JSONB_ARRAY_LENGTH(JSONB_PATH_QUERY_ARRAY(structural, '#{MEMBER_ORDERS_JSON_PATH}')) > 0
      LIMIT #{limit}
    SQL
  end

  def constituent_druid_sql
    self.class.constituent_druid_sql(limit:)
  end

  def catalog_record_id_report_csv
    CSV.generate do |csv|
      catalog_record_id_report_rows.each { |catalog_record_id_report_row| csv << catalog_record_id_report_row }
    end
  end

  def parent_report_csv
    CSV.generate do |csv|
      parent_report_rows.each { |parent_report_row| csv << parent_report_row }
    end
  end

  # * query for a list of all virtual object druids and their constituent druids
  # * build a hash that maps in the other direction, from constituent to parent
  def fetch_member_orders_by_druid_and_constituent_parents
    @constituent_info = {}
    @member_orders_by_druid =
      ActiveRecord::Base.connection.execute(constituent_druid_sql).map do |row|
        parsed_constituent_druids = JSON.parse(row['constituent_druids'])
        parsed_constituent_druids.each do |constituent_druid|
          @constituent_info[constituent_druid] = { parent_druids: [] } unless @constituent_info.key?(constituent_druid)
          @constituent_info[constituent_druid][:parent_druids] << row['vobj_external_identifier']
        end
        [row['vobj_external_identifier'], parsed_constituent_druids, row['constituent_druids_count']]
      end
  end

  # assumes #fetch_member_orders_by_druid_and_constituent_parents already run.
  # for each constituent druid we've already found in that first query, look up the constituent's record, and store any CatalogRecordIds it might have.
  def fetch_constituent_catalog_record_ids
    fetch_member_orders_by_druid_and_constituent_parents
    constituent_info.each_key do |constituent_druid|
      dro = Dro.find_by(external_identifier: constituent_druid)
      @constituent_info[constituent_druid][:catalog_record_ids] = dro.identification['catalogLinks'].select { |catalog_link| catalog_link['catalog'] == 'folio' }
    end
  end

  # a list of two value lists for use in making a CSV: a constituent druid, and one of its
  # catalog_record_ids (if a constituent has multiple catalog_record_ids, it will have multiple rows)
  def catalog_record_id_report_rows
    constituent_info_with_catalog_record_ids = constituent_info.select { |_druid, info_hash| info_hash[:catalog_record_ids].present? }
    constituent_info_with_catalog_record_ids.map do |druid, info_hash|
      info_hash[:catalog_record_ids].map { |catalog_link| [druid, catalog_link['catalogRecordId']] }.flatten
    end
  end

  # a list of two value lists for use in making a CSV: a constituent druid, and one of its
  # virtual object parent druids (if a constituent has multiple parents, it will have multiple rows)
  def parent_report_rows
    constituent_info.map do |druid, info_hash|
      info_hash[:parent_druids].map { |parent_druid| [druid, parent_druid] }.flatten
    end
  end
end
