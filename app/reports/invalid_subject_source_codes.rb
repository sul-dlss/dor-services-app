# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidSubjectSourceCodes.report"
#
# rubocop:disable Metrics/CollectionLiteralLength
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
  MARC_ALL_SOURCE_CODES = %w[
    abne anb banqa bibalex bibbi bnfnaf cantic ccucaut cerlt ckhw conorcg
    conorsi conorsr czenas dib fautor finaf gkd gnd hapi hkcan iconauth
    idref lacnaf mitos naf nalnaf nli -nliaf nlmnaf nta ntc ntd nznb sanb
    snac sucnsaf teka twnaf ulan unbisn vera
    aass aat aatnor aedoml afo afset agrifors agrovoc agrovocf agrovocs
    ahecc aiatsisl aiatsisp aiatsiss aktp albt allars anzsic anzsoc anzsrc
    apaist armarc ascdc asced ascl asft ashlnl asrcrfcd asrcseo asrctoa
    asth ated atg atla aucsh ausext bare barn bdrc bella bet bhammf bhashe
    bhb bib1814 biccbmc bicssc bidex bisacmt bisacrt bisacsh bjornson blcpss
    blmlsh blnpn bokbas bt btr buscem cccv cabt cash cbktrf cck cckthema
    ccsa cct ccte cctf cdcng ceeus cgpa cgndb chirosh cht ciesiniv cilla
    collett csahssa csalsct csapa csh csht cstud cyac czmesh dbcsh dbn dcs
    ddcri ddcrit ddcut dhb-jdg dicgenam dicgenes dicgentop dissao dit dltlt
    dltt drama dtict dugfr ebfem eclas eet eflch eks elsst embehu embiaecid
    embne embucm embus embuz emnmus ept erfemn ericd esar est etiras etuesh
    etuturkob eum eurovoc eurovocen eurovoces eurovocfr eurovocsl fast fcb
    fes finmesh fire flgeo fmesh fnhl francis frst fssh galestne gbd gccst
    gcipmedia gcipplatform gem gemet geni geonames geonet georeft gnis gpn
    gsso gst gtt habibe habich habifr habiit hamsun helecon henn hlasstg
    hoidokki homoit hrvmesh hrvmr huc humord ibsen ica icpsr idas idsbb
    idszbz idszbzes idszbzna idszbzzg idszbzzh idszbzzk iescs iest ilot
    ilpt inist inspect ipat ipsp iptcnc isis itglit itis itrt jhpb jhpk
    jlabsh juho jupo jurivoc kaa kaba kao kassu kauno kaunokki kdm khib
    kito kitu kkts koko kssbar kta kto ktpt ktta kubikat kula kulo kupu
    labloc lapponica larpcal lcac lcdgt lcsh lcshac lcstt lctgm leaubsh
    lemac lemb liito liv lnmmbr local lst ltcsh lua maaq maknaz maotao mar
    masa mech mero mesh meshscr minecost mipfesd mmm mpirdes msc msh
    mtirdes mts musa muso muzeukc muzeukn muzvukci nal nasat nbdbt nbiemnfag
    ncjt ndlsh neo netc nicem nimacsc niodt nlgaf nlgkk nlgsh nlksh nmaict
    no-ubo-mr noraf noram norbok normesh norvok noubojur noubomn nsbncf
    nskps ntcpsc ntcsd ntids ntissc nzggn odlt ogst opat opms ordnok orgnr
    pana pascal peakbag pepp peri periodo pha pkk pldi pleiades pmbok pmcsg
    pmont pmt poha poliscit popinte pplt ppluk precis prnpdi proqsc prvt
    psychit puho qlit qlsp qnaf qnlsh qrma qrmak qtglit quiding ram rasuqam
    renib reo rero rerovoc rma root rpe rswk rswkaf rugeo rurkp rvm rvmfast
    rvmgd samisk sao sbaa sbiao sbt scbi scgdst scisshl scot sears sesca
    sfit sgc sgce shbe she shsples sigle sipri sk skbb skish skon slem smda
    snt socio solstad sosa soto spines ssg stcv sthus stw swd swemesh taika
    tasmas taxhs tbjvp tef tekord tero tesa tesbhaecid test tgn tha thema
    thesoz thia thla tho thub tips tisa tlka tlsh tmdbm tmdbp tmdbtv trfarn
    trfbmb trfdh trfgr trfoba trfzb trt trtsa tsaij tshd tsht tsr ttka
    ttll tucua udc ukslc ula umitrist unbist unescot unicefirc usaidt usgst
    valo vcaadu vffyl vmj waqaf watrest wgst wikidata worldcat wot wpicsh
    ysa yso zst
    accs acmccs agift agricola agrissc anscr ardocs asb azdocs bar bcl bcmc
    bizga bkl bliss blissc blsrissc bsbddc bwlb cacodoc cadocs ccolon ccpgq
    ccd cddir celex chfbn cidades cjurrom clc clutscny cmedlit codocs cscjb
    cslj cutterec ddc dfg dhb-jdgklass dk5s dopaed egedeklass ekl farl
    farma fcps fiaf fid finagri fivr fivs flarch fldocs fna fnb frtav gadocs
    gccn gfdc geothes gestsk ghbs iadocs ics iconclass ifzs inspec ipc isced
    ivdcc jelc jstormcs kab kfmod kktb knt ksdocs kssb kuvacs laclaw ladocs
    lcc lndn loovs methepp mf-klass midocs misklass mmlcc modocs moys
    mpilcs mpkkl msdocs mtlc mu naics nasasscg nbdocs ncdocs ncsclt nhcp
    niv njb nlm nmdocs no-ujur-cmr no-ujur-cnip no-ureal-ca no-ureal-cb
    no-ureal-cg noterlyd nvdocs nwbib nydocs ohdocs okdocs oosk ordocs
    padocs pcesm pcev pcjv pim pssppbkj rdi rich ridocs rilm roy rpb rubbk
    rubbkd rubbkk rubbkm rubbkmv rubbkn rubbknp rubbko rubbks rueskl
    rugasnti rvk sbb scdocs scia sddocs sdnb sfb siblcs siso skb smm srnlc
    ssd ssgn sswd stub suaslc sudocs swank taikclas taykl teatkl txdocs
    tykoma ubtkl/2 uef undocs upsylon usgslcs utdocs utk utklklass
    utklklassex veera vsiso wadocs whulcs widocs wydocs ykl z zdbs
    alett amg barngf bgtchm bellobv buscxf cbk cjh coarrt dct doll estc
    fbg fgtpcm ftamc gatbeg gemppg gmd gmgpc gnd-carrier gnd-content
    gnd-music gsafd gtlm gtmm gttg isbdcontent isbdmedia lcgft lobt
    marccategory marcform marcgt marcsmd migfg mim msupplcont musvok-sf
    muzeukv nbdbgf ncrbs ncrcarrier ncrcontent ncrcpc ncrfs ncrft ncrmat
    ncrmedia ncrpm ncrpo ncrrm ncrtr ncrvf ndlgft ngl nimafc nlggf nmc nom
    nskzs ntsf nzcoh oabt olacvggt proysen radfg rbbin rbgenr rbmscv rbpap
    rbpri rbprov rbpub rbtyp rda rdaar rdabf rdabs rdacarrier rdacc rdaco
    rdacontent rdacpc rdact rdaep rdafmn rdafnm rdafr rdafs rdaft rdagen
    rdagrp rdagw rdaill rdalay rdamat rdamedia rdami rdamt rdapf rdapm rdapo
    rdare rdarm rdarr rdasco rdaspc rdatb rdatc rdatr rdavf reveal rvmgf
    saogf sgp slm tept tgfbne tgfc tpro vgmsgg vgmsng
  ].freeze

  REGEX = "^(?!#{MARC_ALL_SOURCE_CODES.map { |code| "#{code}$" }.join('|')})".freeze
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as value,
           jsonb_path_query(rov.description, '#{OMIT_JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as omit_value,
           ro.external_identifier,
           jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

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
        next if collection_druid == 'druid:yh583fk3400' # ignore the google books collection

        collection_head_version = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version
        if collection_head_version&.has_cocina?
          collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
        end
        apo_druid = rows.first['apo']
        apo_name = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version&.label
        title = (rows.first['structured_title'] || rows.first['title'])&.delete("\n")

        omit_values = rows.filter_map { |row| row['omit_value'] }.uniq
        keep_values = rows.filter_map { |row| row['value'] unless omit_values.include?(row['value']) }
        next if keep_values.empty?

        [
          id,
          keep_values.join(';'),
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
