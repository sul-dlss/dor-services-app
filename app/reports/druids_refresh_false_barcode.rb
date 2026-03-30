# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DruidsRefreshFalseBarcode.report"
class DruidsRefreshFalseBarcode
  # Query for description and identification metadata for records where the folio catalogRecordId refresh is set to false and there is a barcode.
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,

      jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
      jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == false).catalogRecordId') ->> 0 as catalog_record_id
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE
      ro.external_identifier IN druid_list
      AND
      jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == false)')
      AND
      jsonb_path_exists(rov.identification, '$.barcode')
      AND ro.head_version_id = rov.id;
  SQL

  def self.report
    sql_query = SQL.gsub('druid_list', "(#{DRUIDS.map { |druid| "'#{druid}'" }.join(',')})")
    puts %w[druid structured_title title catalog_record_id].join(',')
    rows(sql_query).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      [
        row['druid'],
        row['structured_title']&.delete('\n'),
        row['title'],
        row['catalog_record_id']
      ].to_csv
    end
  end

  DRUIDS = %w[
    druid:vb441hm7822
    druid:gk026hw6071
    druid:nx413jn5687
    druid:kv336wh1259
    druid:jz162zz7107
    druid:sn635rc9329
    druid:rd112wm6892
    druid:pm116kd5895
    druid:cs416zt8164
    druid:nc042kc6597
    druid:ms695bp8069
    druid:fb815fw2643
    druid:dg142sh0493
    druid:fz804mj7771
    druid:xd717yk2775
    druid:pq313mv8693
    druid:kg670zz3235
    druid:ny600sn7631
    druid:wg243kd4695
    druid:nm760cz5703
    druid:hd499rx8855
    druid:vy472qv6664
    druid:pv318rt3720
    druid:jh629ny6291
    druid:sr357yz1602
    druid:sf078xb3440
    druid:cg880pm9806
    druid:xh707bg0985
    druid:zp400nt7374
    druid:vj133hq2003
    druid:rh748kc9764
    druid:cv190qw7362
    druid:pw301ff3466
    druid:wh993qp4812
    druid:vm884vc4172
    druid:px574bm0214
    druid:cw158fm9079
    druid:jq871wt1008
    druid:xv048mr2247
    druid:ht788rp0508
    druid:xj944bh4800
    druid:vk120hg1733
    druid:tf672wz2836
    druid:nx893bk3125
    druid:wq259nc8531
    druid:pf332qm1704
    druid:yn111zy2078
    druid:hc493wt9154
    druid:rj237hd0262
    druid:cj899vm1618
    druid:bp097yy2090
    druid:ty281rt9011
    druid:dm838vp6271
    druid:zv425vr2911
    druid:fn899mk8413
    druid:th526js5082
    druid:rc976dv0933
    druid:hw697zr3007
    druid:pt460zj3287
    druid:sb216wq3829
    druid:qm063mt8574
    druid:dc578xw0099
    druid:bb310ps0325
    druid:md621vv5849
    druid:sx874kc0003
    druid:ks040rj8422
    druid:sr625xk3507
    druid:dq190mz9042
    druid:pk146my8301
    druid:fy916vw6562
    druid:yw180pw5845
    druid:dq554vv4218
    druid:gh965zn8903
    druid:yq008tm2598
    druid:hw294sq7229
    druid:pk440dc4713
    druid:wf027xk3554
    druid:wv820yy3968
    druid:cs467rm3611
    druid:wr460xy6169
    druid:kq881nv0638
    druid:sc732mv3710
    druid:yj722fg8114
    druid:kf625kj3550
    druid:nk994yr6800
    druid:bb672vr0945
    druid:tr830hp9529
    druid:wv885mk1726
    druid:dd887sd0048
    druid:qn526bq8974
    druid:rp764rv8850
    druid:vt055qs2155
    druid:ck939wc6950
    druid:dn588qp6399
    druid:hn955cq6805
    druid:pq060qr0463
    druid:qj309jn8142
    druid:vq794vg6390
    druid:wf662yd3368
    druid:xg618xw3347
    druid:yn537wj3088
    druid:zj412zf5769
    druid:bc056pk7509
    druid:fh943sy5820
    druid:mf329bz4381
    druid:nr116dw4950
    druid:tv350dc4479
    druid:ww509sc3294
    druid:nh403kr9592
    druid:sd226xp3598
    druid:zj295zp4834
    druid:my234sk6877
    druid:fs499ky8783
    druid:sh510td0722
    druid:zb501rv7432
    druid:mt197vx4279
    druid:xq260bj8449
    druid:xh436sj4515
    druid:yn202nz9969
    druid:ny963jw2949
    druid:vd851ps9716
    druid:nj833mx7067
    druid:tw931cy0093
    druid:jx998fh9120
    druid:jr719sv0472
    druid:yv580fk9831
    druid:rw318fm6039
    druid:rz622wq9724
    druid:kr300js4343
    druid:ks541hy4896
    druid:nv369rt3823
    druid:ss981jy7274
    druid:rf352gn6972
    druid:fq493ns9217
    druid:vt676cd5831
    druid:py067sf2725
    druid:zb201vs2586
    druid:mw989qj7347
    druid:kp904rp5699
    druid:kr999mb2385
    druid:qw124vb0251
    druid:dr973qf4605
    druid:ns987cv6238
    druid:tw309jt9481
    druid:dx768mh3262
    druid:fm742nb7315
    druid:jd037tj6838
    druid:xn273zt2664
    druid:pb063tj4024
    druid:dk239wt3656
    druid:gk976tb8424
    druid:cp798td1808
    druid:mr113hg4849
    druid:rk569wh1194
    druid:by347yv0964
    druid:sm400dr8508
    druid:wv869wg5034
    druid:kb038vc9542
    druid:zf435zd2463
    druid:kt379zq7803
    druid:sy938xf0265
    druid:pj520zv3364
    druid:rp889kh7369
    druid:kj114qh4870
    druid:vh504yr6896
    druid:bj279nw5045
  ].freeze
end
