# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidContributorSourceCodes.report"
class InvalidContributorSourceCodes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.contributor.**.name.**.source.code'
  # rubocop:disable Metrics/CollectionLiteralLength
  MARC_SUBJECT_SOURCE_CODES = %w[
    aass aat aatnor abne aedoml afo afset agrifors agrovoc agrovocf agrovocs
    ahecc aiatsisl aiatsisp aiatsiss aktp albt allars anzsic anzsoc anzsrc
    apaist armarc ascdc asced ascl asft ashlnl asrcrfcd asrcseo asrctoa asth
    ated atg atla aucsh ausext bare barn bdrc bella bet bhammf bhashe bhb
    bib1814 bibalex bibbi biccbmc bicssc bidex bisacmt bisacrt bisacsh
    bjornson blcpss blmlsh blnpn bokbas bt btr buscem cccv cabt cash cbktrf
    cck cckthema ccsa cct ccte cctf cdcng ceeus cgpa cgndb chirosh cht
    ciesiniv cilla collett conorsi conorsr csahssa csalsct csapa csh csht
    cstud cyac czenas czmesh dbcsh dbn dcs ddcri ddcrit ddcut dhb-jdg
    dicgenam dicgenes dicgentop dissao dit dltlt dltt drama dtict dugfr
    ebfem eclas eet eflch eks elsst embehu embiaecid embne embucm embus
    embuz emnmus ept erfemn ericd esar est etiras etuesh etuturkob eum
    eurovoc eurovocen eurovoces eurovocfr eurovocsl fast fcb fes finmesh
    fire flgeo fmesh fnhl francis frst fssh galestne gbd gccst gcipmedia
    gcipplatform gem gemet geni geonames geonet georeft gnd gnis gpn gsso
    gst gtt habibe habich habifr habiit hamsun hapi helecon henn hkcan
    hlasstg hoidokki homoit hrvmesh hrvmr huc humord ibsen ica iconauth
    icpsr idas idref idsbb idszbz idszbzes idszbzna idszbzzg idszbzzh
    idszbzzk iescs iest ilot ilpt inist inspect ipat ipsp iptcnc isis
    itglit itis itrt jhpb jhpk jlabsh juho jupo jurivoc kaa kaba kao kassu
    kauno kaunokki kdm khib kito kitu kkts koko kssbar kta kto ktpt ktta
    kubikat kula kulo kupu labloc lacnaf lapponica larpcal lcac lcdgt lcsh
    lcshac lcstt lctgm leaubsh lemac lemb liito liv lnmmbr local lst ltcsh
    lua maaq maknaz maotao mar masa mech mero mesh meshscr minecost mipfesd
    mmm mpirdes msc msh mtirdes mts musa muso muzeukc muzeukn muzvukci naf
    nal nalnaf nasat nbdbt nbiemnfag ncjt ndlsh neo netc nicem nimacsc niodt
    nlgaf nlgkk nlgsh nli nlksh nlmnaf nmaict no-ubo-mr noraf noram norbok
    normesh norvok noubojur noubomn nsbncf nskps nta ntc ntcpsc ntcsd ntids
    ntissc nzggn nznb odlt ogst opat opms ordnok orgnr pana pascal peakbag
    pepp peri periodo pha pkk pldi pleiades pmbok pmcsg pmont pmt poha
    poliscit popinte pplt ppluk precis prnpdi proqsc prvt psychit puho qlit
    qlsp qnaf qnlsh qrma qrmak qtglit quiding ram rasuqam renib reo rero
    rerovoc rma root rpe rswk rswkaf rugeo rurkp rvm rvmfast rvmgd samisk
    sanb sao sbaa sbiao sbt scbi scgdst scisshl scot sears sesca sfit sgc
    sgce shbe she shsples sigle sipri sk skbb skish skon slem smda snt
    socio solstad sosa soto spines ssg stcv sthus stw swd swemesh taika
    tasmas taxhs tbjvp tef tekord tero tesa tesbhaecid test tgn tha thema
    thesoz thia thla tho thub tips tisa tlka tlsh tmdbm tmdbp tmdbtv trfarn
    trfbmb trfdh trfgr trfoba trfzb trt trtsa tsaij tshd tsht tsr ttka
    ttll tucua udc ukslc ula ulan umitrist unbisn unbist unescot unicefirc
    usaidt usgst valo vcaadu vffyl vmj waqaf watrest wgst wikidata worldcat
    wot wpicsh ysa yso zst
  ].freeze
  MARC_NAME_TITLE_SOURCE_CODES = %w[
    abne anb banqa bibalex bibbi bnfnaf cantic ccucaut cerlt ckhw conorcg
    conorsi conorsr czenas dib fautor finaf gkd gnd hapi hkcan iconauth
    idref lacnaf mitos naf nalnaf nli -nliaf nlmnaf nta ntc ntd nznb sanb
    snac sucnsaf teka twnaf ulan unbisn vera
  ].freeze
  MARC_ORG_SOURCE_CODES = %w[marcorg oclcorg].freeze

  # rubocop:enable Metrics/CollectionLiteralLength

  def self.valid_codes
    MARC_SUBJECT_SOURCE_CODES + MARC_NAME_TITLE_SOURCE_CODES + MARC_ORG_SOURCE_CODES
  end

  def self.regex
    codes = valid_codes
    "^(?!#{codes.map { |code| "#{code}$" }.join('|')})"
  end

  def self.sql
    r = regex
    <<~SQL.squish
      SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex "#{r}")') ->> 0 as value,
             ro.external_identifier,
             jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
             jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
             jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
             jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
             jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
             FROM repository_objects AS ro, repository_object_versions AS rov WHERE
             ro.head_version_id = rov.id
             AND ro.object_type = 'dro'
             AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "#{r}")')
    SQL
  end

  def self.report
    puts "item_druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

    rows(sql).each { |row| puts row }
  end

  def self.rows(query)
    ActiveRecord::Base
      .connection
      .execute(query)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        collection_druid = rows.first['collection_id']
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label
        apo_druid = rows.first['apo']
        apo_name = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version&.label
        title = (rows.first['structured_title'] || rows.first['title'])&.delete("\n")

        [
          id,
          rows.pluck('value').join(';'),
          title,
          collection_druid,
          collection_name,
          rows.first['hrid'],
          apo_druid,
          apo_name
        ].to_csv
      end
  end
end
