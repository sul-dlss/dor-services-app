# frozen_string_literal: true

# objects with values in ..identifier.source.code that are not in the list at https://www.loc.gov/standards/sourcelist/standard-identifier.html
# Invoke via:
# bin/rails r -e production "InvalidIdentifierSourceCodes.report"
class InvalidIdentifierSourceCodes
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.identifier[*].source.code'

  LOC_IDENTIFIER_SOURCE_CODES = %w[
    agorha agrovoc allmovie allmusic allocine amnbo ansi archinl
    archinpe archinpr archna archns ark artsy artukart artukaw
    arxiv atg ausbn auscn ausnzst ausrn ausst balat
    bbcth bbrainza bbrainzp bbrainzw bdusc bdrc belvku belvwrk
    benezit bew bfi bhb bibbi bigenc bmdb bnfcg
    bpn bsi cabt cana cantic cbwpid cerl cgndb
    clara cnbksy conccc csfdcz danacode darome datoses discogs
    dkfilm dma doi dpb ean ecli eidr emanus-vlid
    emlo erara-vlid elsst famsea fast fidecp filmaff filmport
    findagr fisa freebase fuoc gacsch gec gemet geogndb
    geonames geprishisp gettyaat gettyart gettyobj gettytgn gettyulan gnd
    gnis goodra gtaa gtin-14 hdl Handle iaafa ibdb
    iconauth iconclass idref ilot imdb inspire isan isbn
    isbn-a isbnre isbnsbn ismn isni iso isfdbau isfdbaw
    isfdbma isfdbpu isil isrc issn issn-l issue-number istc
    iswc it-acnp itar kaken kda kdw kinopo knpam
    ktga ktgw kulturnav lattes lccn lcmd lei libaus
    lmhl local margaz manto matrix-number mesh mggo mocofo
    moma morana moviemetf moviemetr munzing muscl music-plate music-publisher
    musicb nacat nagb natgazfid nga ngva ngvw nii
    nipo nlg nli nndb npg nstc nzggn nzst
    oalex odnb ofdb onix openlib opensm orcid orgnr
    oxforddnb pcadbu pares pcadpe pcadpf permid picnypl pleiades
    pmc pmid pnta porthu prabook rdt rid rijkspid
    rism rkda ror s2a3bd saam schins scholaru schsch
    scope scopus sici smgp snac spotify sprfbsb sprfbsk
    sprfcbb sprfcfb sprfhoc sprfoly sprfpfb ssaut stock-number strn
    stw svfilm tatearid theatr tmdbm tmdbp tmdbtv tpce
    trove twnaf unbist unescot upc urbe uri urn
    vd16 vd17 vd18 vera vgmdb viaf videorecording-identifier wikidata
    wndla worldcat xgamea zbaut
  ].freeze

  def self.regex
    "^(?!#{LOC_IDENTIFIER_SOURCE_CODES.map { |code| "#{code}$" }.join('|')})"
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
