# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Checks and fixes status: primary
      class Primary
        # @params [Nokogiri::XML::NodeSet] node_set
        # @params [String] type the value of a node's type attribute we are concerned with
        def self.adjust(node_set, type, notifier, match_type: false)
          primary_node_set = node_set.select { |node| node[:status] == 'primary' && (!match_type || node[:type] == type) }

          return node_set if primary_node_set.size < 2

          primary_node_set[1..].each { |node| node.delete(:status) }

          notifier.warn('Multiple marked as primary', { type: type })
          node_set
        end
      end
    end
  end
end
