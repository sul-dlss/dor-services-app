# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidScriptCode.report"
class InvalidValueScriptCode
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.valueLanguage.valueScript.code'

  def self.valid_codes
    # These were extracted from https://www.unicode.org/iso15924/iso15924.txt
    # as of 5/13/2026
    %w[Adlm Afak Aghb Ahom Arab Aran Armi Armn Avst Bali
       Bamu Bass Batk Beng Berf Bhks Blis Bopo Brah Brai
       Bugi Buhd Cakm Cans Cari Cham Cher Chis Chrs Cirt
       Copt Cpmn Cprt Cyrl Cyrs Deva Diak Dogr Dsrt Dupl
       Egyd Egyh Egyp Elba Elym Ethi Gara Geok Geor Glag
       Gong Gonm Goth Gran Grek Gujr Gukh Guru Hanb Hang
       Hani Hano Hans Hant Hatr Hebr Hira Hluw Hmng Hmnp
       Hntl Hrkt Hung Inds Ital Jamo Java Jpan Jurc Kali
       Kana Kawi Khar Khmr Khoj Kitl Kits Knda Kore Kpel
       Krai Kthi Lana Laoo Latf Latg Latn Leke Lepc Limb
       Lina Linb Lisu Loma Lyci Lydi Mahj Maka Mand Mani
       Marc Maya Medf Mend Merc Mero Mlym Modi Mong Moon
       Mroo Mtei Mult Mymr Nagm Nand Narb Nbat Newa Nkdb
       Nkgb Nkoo Nshu Ogam Olck Onao Orkh Orya Osge Osma
       Ougr Palm Pauc Pcun Pelm Perm Phag Phli Phlp Phlv
       Phnx Plrd Piqd Prti Psin Qaaa Qabx Ranj Rjng Rohg
       Roro Runr Samr Sara Sarb Saur Seal Sgnw Shaw Shrd
       Shui Sidd Sidt Sind Sinh Sogd Sogo Sora Soyo Sund
       Sunu Sylo Syrc Syre Syrj Syrn Tagb Takr Tale Talu
       Taml Tang Tavt Tayo Telu Teng Tfng Tglg Thaa Thai
       Tibt Tirh Tnsa Todr Tols Toto Tutg Ugar Vaii Visp
       Vith Wara Wcho Wole Xpeo Xsux Yezi Yiii Zanb Zinh
       Zmth Zsye Zsym Zxxx Zyyy Zzzz]
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
        collection_head_version = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version
        if collection_head_version&.has_cocina?
          collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
        end
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
