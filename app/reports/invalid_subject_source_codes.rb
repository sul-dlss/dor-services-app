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
  OMIT_JSON_PATH = 'strict $.**.subject.**.valueLanguage.**.source.code'
  VALID_CODES = %w[
    aat
    abne
    afset
    agrovoc
    aiatsisl
    aiatsisp
    aiatsiss
    anscr
    ascl
    bcl
    bcmc
    bidex
    bisacsh
    bkl
    blmlsh
    blsrissc
    cadocs
    cct
    cdcng
    clc
    csh
    csht
    czenas
    dcs
    ddc
    ddcrit
    dopaed
    dtict
    eclas
    eflch
    embne
    ericd
    eurovocen
    farl
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
    ifzs
    ISO19115TopicCategory
    itrt
    jhpb
    jhpk
    jlabsh/3
    jlabsh/4
    kktb
    kssb
    larpcal
    lcc
    lcgft
    lcsh
    lcshac
    lctgm
    lemb
    local
    loovs
    ltcsh
    marcgac
    marcrelator
    mesh
    moys
    msc
    naf
    nal
    nasat
    ncsclt
    ndlsh
    njb
    njb/9
    nli
    nlm
    nta
    precis
    psychit
    qlsp
    ram
    rasuqam
    renib
    reo
    rero
    rpb
    rswk
    rvk
    rvm
    sao
    sbb
    scgdst
    sdnb
    sears
    sfb
    sigle
    sk
    ssg
    ssgn
    sswd
    stub
    stw
    sudocs
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
    zdbs
  ].freeze
  REGEX = "^(?!#{VALID_CODES.map { |code| "#{code}$" }.join('|')})".freeze
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as value,
           jsonb_path_query(rov.description, '#{OMIT_JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as omit_value,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,collection_name,value\n"

    rows(SQL).each { |row| puts row if row }
  end

  def self.rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        collection_druid = rows.first['collection_id']
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

        omit_values = rows.filter_map { |row| row['omit_value'] }.uniq
        keep_values = rows.filter_map { |row| row['value'] unless omit_values.include?(row['value']) }
        next if keep_values.empty?

        [
          id,
          rows.first['catalogRecordId'],
          collection_druid,
          collection_name,
          keep_values.join(';')
        ].to_csv
      end
  end
end
# rubocop:enable Metrics/ClassLength
