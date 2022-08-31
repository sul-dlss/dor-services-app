# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidSubjectSourceCodes.report"
#
# rubocop:disable Metrics/ClassLength
class InvalidSubjectSourceCodes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.subject.**.source.code'
  VALID_CODES = %w[
    aat
    abne
    afset
    agrovoc
    aiatsisl
    aiatsisp
    aiatsiss
    ascl
    bidex
    bisacsh
    blmlsh
    cct
    cdcng
    csh
    csht
    czenas
    dcs
    ddc
    ddcrit
    dtict
    eclas
    eflch
    embne
    ericd
    eurovocen
    fast
    fmesh
    fssh
    ftamc
    geonames
    geonet
    gnd
    gtt
    henn
    idsbb
    idszbz
    idszbzzk
    ISO19115TopicCategory
    itrt
    jhpb
    jhpk
    jlabsh/3
    jlabsh/4
    larpcal
    lcc
    lcgft
    lcsh
    lcshac
    lctgm
    lemb
    local
    ltcsh
    marcgac
    marcrelator
    mesh
    msc
    naf
    nal
    nasat
    ndlsh
    nli
    nta
    precis
    psychit
    qlsp
    ram
    rasuqam
    renib
    reo
    rero
    rswk
    rvm
    sao
    scgdst
    sears
    sigle
    sk
    ssg
    stw
    swd
    swd/690
    tgn
    tlsh
    trt
    udc
    ukslc
    unbisn
    unbist
    wikidata
    wot
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
# rubocop:enable Metrics/ClassLength
