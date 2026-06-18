# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidEventLocationCodes.report"
class InvalidEventLocationCodes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = '$.**.event.location.code'

  # rubocop:disable Metrics/CollectionLiteralLength
  def self.valid_codes
    # These were extracted from https://www.loc.gov/marc/countries/countries_code.html
    # as of 5/18/2026
    %w[
      aa abc ac aca ae af ag ai ai air aj ajr aku alu am an ao aq aru as at
      au aw ay azu ba bb bcc bd be bf bg bh bi bl bm bn bo bp br bs bt bu bv bw
      bwr bx ca cau cb cc cd ce cf cg ch ci cj ck cl cm cn co cou cp cq cr
      cs ctu cu cv cw cx cy cz dcu deu dk dm dq dr ea ec eg em enk er err es
      et fa fg fi fj fk flu fm fp fr fs ft gau gb gd ge gg gh gi gl gm gn go
      gp gr gs gsr gt gu gv gw gy gz hiu hk hm ho ht hu iau ic idu ie ii ilu
      im inu io iq ir is it iu iv iw iy ja je ji jm jn jo ke kg kgr kn ko
      ksu ku kv kyu kz kzr lau lb le lh li lir ln lo ls lu lv lvr ly mau
      mbc mc mdu meu mf mg mh miu mj mk ml mm mnu mo mou mp mq mr msu mtu mu
      mv mvr mw mx my mz na nbu ncu ndu ne nfc ng nhu nik nju nkc nl nm nmu
      nn no np nq nr nsc ntc nu nuc nvu nw nx nyu nz ohu oku onc oru ot pau pc
      pe pf pg ph pic pk pl pn po pp pr pt pw py qa qea quc rb re rh riu rm ru
      rur rw ry sa sb sc scu sd sdu se sf sg sh si sj sk sl sm sn snc so sp
      sq sr ss st stk su sv sw sx sy sz ta tar tc tg th ti tk tkr tl tma tnu
      to tr ts tt tu tv txu tz ua uc ug ui uik uk un unr up ur us utu uv
      uy uz uzr vau vb vc ve vi vm vn vp vra vs vtu wau wb wea wf wiu wj wk
      wlk ws wvu wyu xa xb xc xd xe xf xga xh xi xj xk xl xm xn xna xo xoa
      xp xr xra xs xv xx xxc xxk xxr xxu ye ykc ys yu za
    ]
  end
  # rubocop:enable Metrics/CollectionLiteralLength

  def self.regex
    # codes = valid_codes
    "^(?!#{valid_codes.map { |code| "#{code}$" }.join('|')})"
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
