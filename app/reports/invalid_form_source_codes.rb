# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidFormSourceCodes.report"
class InvalidFormSourceCodes
  JSON_PATH = 'strict $.**.form.**.source.code'
  VALID_CODES = %w[
    aat EPSG eurovoc fast ftamc gcipmedia gmd gmgpc gnd gnd-content gsafd gtlm gtt
    idszbz isbdcontent isbdmedia larpcal lcgft lcmpt lcsh local marccarrier marccategory
    marcform marcgt marcmuscomp marcsmd mesh migfg nal ngl nli olacvggt rasuqam rbbin
    rbgenr rbpap rbpri rbprov rbpub rbtyp rdacarrier rdacarrier/dut rdacarrier/eng
    rdacarrier/fre rdacarrier/ger rdacarrier/pol rdacontent rdacontent/dut rdacontent/eng
    rdacontent/fre rdacontent/ger rdacontent/pol rdamedia rdamedia/dut rdamedia/eng
    rdamedia/fre rdamedia/ger rdamedia/pol rvmgf sears swd
  ].freeze
  REGEX = "^(?!#{VALID_CODES.map { |code| "#{code}$" }.join('|')})".freeze
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as value,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,collection_name,value\n"

    rows(SQL).each { |row| puts row }
  end

  def self.rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
      collection_druid = rows.first['collection_id']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        id,
        rows.first['catkey'],
        collection_druid,
        "\"#{collection_name}\"",
        rows.map { |row| row['value'] }.join(';')
      ].join(',')
    end
  end
end
