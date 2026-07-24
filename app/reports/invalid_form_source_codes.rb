# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidFormSourceCodes.report"
#
# rubocop:disable Metrics/CollectionLiteralLength
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

  # Valid codes from https://www.loc.gov/standards/sourcelist/subject.html
  # and https://www.loc.gov/standards/sourcelist/genre-form.html (deduplicated)
  VALID_CODES = %w[
    aass aat aatnor abne aedoml afo afset agrifors agrovoc agrovocf agrovocs
    ahecc aiatsisl aiatsisp aiatsiss aktp albt alett allars amg anzsic anzsoc
    anzsrc apaist armarc ascdc asced ascl asft ashlnl asrcrfcd asrcseo asrctoa
    asth ated atg atla aucsh ausext bare barn barngf bdrc bella bellobv bet
    bgtchm bhammf bhashe bhb bib1814 bibalex bibbi biccbmc bicssc bidex bisacmt
    bisacrt bisacsh bjornson blcpss blmlsh blnpn bokbas bt btr buscem buscxf
    cabt cash cbk cbktrf cccv cck cckthema ccsa cct ccte cctf cdcng ceeus cgndb
    cgpa chirosh cht ciesiniv cilla cjh coarrt collett conorsi conorsr csahssa
    csalsct csapa csh csht cstud cyac czenas czmesh dbcsh dbn dcs dct ddcri
    ddcrit ddcut dhb-jdg dicgenam dicgenes dicgentop dissao dit dltlt dltt doll
    drama dtict dugfr ebfem eclas eet eflch eks elsst embehu embiaecid embne
    embucm embus embuz emnmus ept erfemn ericd esar est estc etiras etuesh
    etuturkob eum eurovoc eurovocen eurovoces eurovocfr eurovocsl fast fbg fcb
    fes fgtpcm finmesh fire flgeo fmesh fnhl francis frst fssh ftamc galestne
    gatbeg gbd gccst gcipmedia gcipplatform gem gemet gemppg geni geonames
    geonet georeft gmd gmgpc gnd gnd-carrier gnd-content gnd-music gnis gpn
    gsafd gsso gst gtlm gtmm gtt gttg habibe habich habifr habiit hamsun hapi
    helecon henn hkcan hlasstg hoidokki homoit hrvmesh hrvmr huc humord ibsen
    ica iconauth icpsr idas idref idsbb idszbz idszbzes idszbzna idszbzzg
    idszbzzh idszbzzk iescs iest ilot ilpt inist inspect ipat ipsp iptcnc
    isbdcontent isbdmedia isis itglit itis itrt jhpb jhpk jlabsh juho jupo
    jurivoc kaa kaba kao kassu kauno kaunokki kdm khib kito kitu kkts koko
    kssbar kta kto ktpt ktta kubikat kula kulo kupu labloc lacnaf lapponica
    larpcal lcac lcdgt lcgft lcsh lcshac lcstt lctgm leaubsh lemac lemb liito
    liv lnmmbr lobt local lst ltcsh lua maaq maknaz maotao mar marccategory
    marcform marcgt marcsmd masa mech mero mesh meshscr migfg mim minecost
    mipfesd mmm mpirdes msc msh msupplcont mtirdes mts musa muso musvok-sf
    muzeukc muzeukn muzeukv muzvukci naf nal nalnaf nasat nbdbgf nbdbt nbiemnfag
    ncjt ncrbs ncrcarrier ncrcontent ncrcpc ncrfs ncrft ncrmat ncrmedia ncrpm
    ncrpo ncrrm ncrtr ncrvf ndlgft ndlsh neo netc ngl nicem nimacsc nimafc niodt
    nlgaf nlggf nlgkk nlgsh nli nlksh nlmnaf nmaict nmc no-ubo-mr nom noraf
    noram norbok normesh norvok noubojur noubomn nsbncf nskps nskzs nta ntc
    ntcpsc ntcsd ntids ntissc ntsf nzcoh nzggn nznb oabt odlt ogst olacvggt
    opat opms ordnok orgnr pana pascal peakbag pepp peri periodo pha pkk pldi
    pleiades pmbok pmcsg pmont pmt poha poliscit popinte pplt ppluk precis
    prnpdi proqsc proysen prvt psh psychit puho qlit qlsp qnaf qnlsh qrma qrmak
    qtglit quiding radfg ram rasuqam rbbin rbgenr rbmscv rbpap rbpri rbprov
    rbpub rbtyp rda rdaar rdabf rdabs rdacarrier rdacc rdaco rdacontent rdacpc
    rdact rdaep rdafmn rdafnm rdafr rdafs rdaft rdagen rdagrp rdagw rdaill
    rdalay rdamat rdamedia rdami rdamt rdapf rdapm rdapo rdare rdarm rdarr
    rdasco rdaspc rdatb rdatc rdatr rdavf renib reo rero rerovoc reveal rma root
    rpe rswk rswkaf rugeo rurkp rvm rvmfast rvmgd rvmgf samisk sanb sao saogf
    sbaa sbiao sbt scbi scgdst scisshl scot sears sesca sfit sgc sgce sgp shbe
    she shsples sigle sipri sk skbb skish skon slem slm smda snt socio solstad
    sosa soto spines ssg stcv sthus stw swd swemesh taika tasmas taxhs tbjvp
    tef tekord tept tero tesa tesbhaecid test tgfbne tgfc tgn tha thema thesoz
    thia thla tho thub tips tisa tlka tlsh tmdbm tmdbp tmdbtv tpro trfarn trfbmb
    trfdh trfgr trfoba trfzb trt trtsa tsaij tshd tsht tsr ttka ttll tucua udc
    ukslc ula ulan umitrist unbisn unbist unescot unicefirc usaidt usgst valo
    vcaadu vffyl vgmsgg vgmsng vmj waqaf watrest wgst wikidata worldcat wot
    wpicsh ysa yso zst marccarrier lcmpt
  ].freeze
  REGEX = "^(?!#{VALID_CODES.map { |code| "#{code}$" }.join('|')})".freeze
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as value,
           ro.external_identifier,
           jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

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
      collection_head_version = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version
      if collection_head_version&.has_cocina?
        collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
      end
      apo_druid = rows.first['apo']
      apo_head_version = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version
      if apo_head_version&.has_cocina?
        apo_description = apo_head_version.to_cocina.description
        apo_name = Cocina::Models::Builders::TitleBuilder.build(apo_description.title) if apo_description
      end
      title = (rows.first['structured_title'] || rows.first['title'])&.delete("\n")

      [
        id,
        rows.pluck('value').uniq.join(';'),
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
# rubocop:enable Metrics/CollectionLiteralLength
