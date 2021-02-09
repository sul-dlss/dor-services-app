# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Checks and fixes status: primary
      class Primary
        def self.adjust(items, type, notifier, match_type: false)
          primary_items = items.select { |item| item[:status] == 'primary' && (!match_type || item[:type] == type) }

          return items if primary_items.size < 2

          primary_items[1..].each { |item| item.delete(:status) }

          notifier.warn('Multiple marked as primary', { type: type })
          items
        end
      end
    end
  end
end
