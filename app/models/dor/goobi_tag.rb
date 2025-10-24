# frozen_string_literal: true

module Dor
  # This represents a tag from Argo that we want to pass to Goobi.
  # So the tag from Argo:
  #   Part1 : Part2 : Part3
  # Is represented as:
  #   <tag name="Part1" value="Part2 : Part3"></tag>
  class GoobiTag
    attr_accessor :name, :value

    def initialize(p_hash)
      @name = p_hash[:name]
      @value = p_hash[:value]
    end

    def to_xml
      Nokogiri::XML::Node.new('tag', Nokogiri::XML::Document.new).tap do |node|
        node['name'] = name
        node['value'] = value
      end.to_xml
    end
  end
end
