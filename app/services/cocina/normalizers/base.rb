# frozen_string_literal: true

module Cocina
  module Normalizers
    # Shared methods available to normalizer class instances
    module Base
      def regenerate_ng_xml(xml)
        @ng_xml = Nokogiri::XML(xml) { |config| config.default_xml.noblanks }
      end
    end
  end
end
