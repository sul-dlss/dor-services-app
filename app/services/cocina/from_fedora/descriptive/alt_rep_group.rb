# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Splits nodes by altRepGroup ids
      class AltRepGroup
        # @param [Array<Nokogiri::XML::Element>] nodes to split
        # @return [Array<Array<Nokogiri::XML::Element>>, Array<Nokogiri::XML::Element>] nodes grouped by altRepGroup, other nodes
        def self.split(nodes:)
          all_nodes_with_altrepgroup = nodes.reject { |node| node[:altRepGroup].blank? }
          grouped_altrepgroup_nodes = all_nodes_with_altrepgroup
                                      .group_by { |node| node[:altRepGroup] }
                                      .values
                                      .reject { |group_nodes| group_nodes.size == 1 }

          other_nodes = nodes.reject { |node| grouped_altrepgroup_nodes.flatten.include?(node) }

          [grouped_altrepgroup_nodes, other_nodes]
        end
      end
    end
  end
end
