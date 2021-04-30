# frozen_string_literal: true

module Cocina
  module FromFedora
    # Maps viewing direction / reading order
    class ViewingDirectionHelper
      VIEWING_DIRECTION_FOR_CONTENT_TYPE = {
        'Book (ltr)' => 'left-to-right',
        'Book (rtl)' => 'right-to-left',
        'Book (flipbook, ltr)' => 'left-to-right',
        'Book (flipbook, rtl)' => 'right-to-left',
        'Manuscript (flipbook, ltr)' => 'left-to-right',
        'Manuscript (ltr)' => 'left-to-right'
      }.freeze

      def self.viewing_direction(druid:, content_ng_xml:)
        reading_direction = content_ng_xml.xpath('//bookData/@readingOrder').first&.value
        # See https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=DOR+content+types%2C+resource+types+and+interpretive+metadata
        case reading_direction
        when 'ltr'
          'left-to-right'
        when 'rtl'
          'right-to-left'
        else
          # Fallback to using tags.  Some books don't have bookData nodes in contentMetadata XML.
          # When we migrate from Fedora 3, we don't need to look this up from AdministrativeTags
          content_type = AdministrativeTags.content_type(pid: druid).first
          VIEWING_DIRECTION_FOR_CONTENT_TYPE[content_type]
        end
      end
    end
  end
end
