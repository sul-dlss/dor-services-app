# frozen_string_literal: true

require 'equivalent-xml'
require 'text'

# Determines if MODS documents are equivalent.
class ModsEquivalentService
  include Dry::Monads[:result]

  Difference = Struct.new(:mods_node1, :mods_node2)

  # @param [Nokogiri::Document] mods_ng_xml1 MODS to be compared against (expected)
  # @param [Nokogiri::Document] mods_ng_xml2 MODS to be compared (actual)
  # @return [Result] Success if equivalent, Failure (including diffs) if not
  def self.equivalent?(mods_ng_xml1, mods_ng_xml2)
    ModsEquivalentService.new(mods_ng_xml1, mods_ng_xml2).equivalent?
  end

  def initialize(mods_ng_xml1, mods_ng_xml2)
    @mods_ng_xml1 = mods_ng_xml1
    @mods_ng_xml2 = mods_ng_xml2
  end

  def equivalent?
    return Success() if EquivalentXml.equivalent?(mods_ng_xml1, mods_ng_xml2)

    Failure(diff)
  end

  private

  attr_reader :mods_ng_xml1, :mods_ng_xml2

  def diff
    mods_nodes1.map do |mods_node1|
      next nil if has_equivalent_node?(mods_node1)

      Difference.new(mods_node1, find_closest_node(mods_node1))
    end.compact
  end

  def mods_nodes1
    @mods_nodes1 ||= mods_ng_xml1.root.xpath('mods:*', mods: Dor::DescMetadataDS::MODS_NS)
  end

  def mods_nodes2
    @mods_nodes2 ||= mods_ng_xml2.root.xpath('mods:*', mods: Dor::DescMetadataDS::MODS_NS)
  end

  def mods_nodes2_without_equivalent
    @mods_nodes2_without_equivalent ||= mods_nodes2.select do |mods_node2|
      mods_nodes1.none? { |mods_node1| EquivalentXml.equivalent?(mods_node1, mods_node2) }
    end
  end

  def has_equivalent_node?(mods_node1)
    mods_nodes2.any? { |mods_node2| EquivalentXml.equivalent?(mods_node1, mods_node2) }
  end

  def find_closest_node(mods_node1)
    mods_nodes2_with_same_tag = mods_nodes2_without_equivalent.select { |mods_node2| mods_node2.name == mods_node1.name }

    return nil if mods_nodes2_with_same_tag.empty?
    return mods_nodes2_with_same_tag.first if mods_nodes2_with_same_tag.size == 1

    distances = {}
    mods_nodes2_with_same_tag.each { |mods_node2| distances[Text::Levenshtein.distance(mods_node1.to_s, mods_node2.to_s)] = mods_node2 }

    distances[distances.keys.min]
  end
end
