# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidFormSourceCodes.report"
class InvalidFormSourceCodes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
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
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,collection_name,value\n"

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
        rows.first['catalogRecordId'],
        collection_druid,
        "\"#{collection_name}\"",
        rows.pluck('value').join(';')
      ].join(',')
    end
  end
end
