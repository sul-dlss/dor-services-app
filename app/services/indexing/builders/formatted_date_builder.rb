# frozen_string_literal: true

module Indexing
  module Builders
    # Builds formatted date fields for a solr document
    class FormattedDateBuilder
      ZONE = ActiveSupport::TimeZone.new('Pacific Time (US & Canada)')

      def self.build(date)
        return unless date

        date.in_time_zone(ZONE).strftime('%Y-%m-%d %r')
      end
    end
  end
end
