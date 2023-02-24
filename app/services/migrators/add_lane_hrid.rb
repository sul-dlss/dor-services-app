# frozen_string_literal: true

module Migrators
  # Adds Lane HRIDs.
  # See https://github.com/sul-dlss/dor-services-app/issues/4388 for context.
  class AddLaneHrid < Base
    def self.druids
      HRID_MAP.keys
    end

    def migrate?
      HRID_MAP.key?(obj.external_identifier) && !has_hrid?
    end

    def migrate
      catalog_links << { 'catalogRecordId' => hrid, 'catalog' => 'folio', 'refresh' => true }
    end

    def version?
      true
    end

    def version_description
      'Add Lane HRID'
    end

    private

    def hrid
      @hrid ||= HRID_MAP.fetch(obj.external_identifier)
    end

    def has_hrid?
      catalog_links.any? { |link| link['catalogRecordId'] == hrid }
    end

    def catalog_links
      @catalog_links ||= obj.identification['catalogLinks'] ||= []
    end

    HRID_MAP = {
      'druid:xx702qn0170' => 'L79041',
      'druid:wc042cz6208' => 'L114671',
      'druid:gt417zw6352' => 'L35131',
      'druid:rr941xv3570' => 'L35162',
      'druid:hs702zb1215' => 'L35167',
      'druid:rt260gd2393' => 'L118281',
      'druid:by152np7439' => 'L235413',
      'druid:bm895yk7224' => 'L28378',
      'druid:cd725bh4815' => 'L28378',
      'druid:dd038mh1111' => 'L28378',
      'druid:dr701zd1352' => 'L28378',
      'druid:fx221zq1082' => 'L28378',
      'druid:gv771sf2444' => 'L28378',
      'druid:hh193pk7111' => 'L28378',
      'druid:hp816vn7251' => 'L28378',
      'druid:hw036dx0760' => 'L28378',
      'druid:jk446kp6308' => 'L28378',
      'druid:jy737kw9967' => 'L28378',
      'druid:mg200ym2208' => 'L28378',
      'druid:mh907nd7370' => 'L28378',
      'druid:nj308dq4212' => 'L28378',
      'druid:np820mm6622' => 'L28378',
      'druid:pd514qp6594' => 'L28378',
      'druid:pz927cc5032' => 'L28378',
      'druid:qb354dg1588' => 'L28378',
      'druid:qw952fj1420' => 'L28378',
      'druid:rc082fp0541' => 'L28378',
      'druid:sk549jr0359' => 'L28378',
      'druid:ts582jh7602' => 'L28378',
      'druid:vj723gg3770' => 'L28378',
      'druid:vm714zs7289' => 'L28378',
      'druid:vv024th7904' => 'L28378',
      'druid:wf990sm5026' => 'L28378',
      'druid:wh261jh3899' => 'L28378',
      'druid:wk032ss9426' => 'L28378',
      'druid:mm864yc3789' => 'L53910',
      'druid:xq947mb3618' => 'L72691',
      'druid:vd642zn6271' => 'L37284',
      'druid:wk893wq1954' => 'L229317',
      'druid:fk146vz6391' => 'L242032',
      'druid:hf919mq6533' => 'L289256',
      'druid:dq600bz2460' => 'L52290',
      'druid:yt853xt1638' => 'L71998',
      'druid:dm104ny0726' => 'L76407',
      'druid:cx804cx9497' => 'L72550',
      'druid:qn269jk7253' => 'L72036',
      'druid:kd326ph9316' => 'L69828',
      'druid:qs342dv7909' => 'L309102',
      'druid:jd326wm8459' => 'L294501',
      # This is on QA only (does not exist on prod)
      'druid:bc836hv7886' => 'L123456'
    }.freeze
  end
end
