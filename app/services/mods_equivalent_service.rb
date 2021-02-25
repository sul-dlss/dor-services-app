# frozen_string_literal: true

require 'equivalent-xml'
require 'set'

# Determines if MODS documents are equivalent.
class ModsEquivalentService
  include Dry::Monads[:result]

  Difference = Struct.new(:mods_node1, :mods_node2)

  # @param [Nokogiri::Document] mods_ng_xml1 MODS to be compared against (expected)
  # @param [Nokogiri::Document] mods_ng_xml2 MODS to be compared (actual)
  # @return [Result] Success if equivalent, Failure (including diffs) if not
  def self.equivalent_with_result?(mods_ng_xml1, mods_ng_xml2)
    ModsEquivalentService.new(mods_ng_xml1, mods_ng_xml2).equivalent_with_result?
  end

  # @param [Nokogiri::Document] mods_ng_xml1 MODS to be compared against (expected)
  # @param [Nokogiri::Document] mods_ng_xml2 MODS to be compared (actual)
  # @return [Boolean] True if equivalent, False if not
  def self.equivalent?(mods_ng_xml1, mods_ng_xml2)
    ModsEquivalentService.new(mods_ng_xml1, mods_ng_xml2).equivalent?
  end

  def initialize(mods_ng_xml1, mods_ng_xml2)
    @mods_ng_xml1 = mods_ng_xml1
    @mods_ng_xml2 = mods_ng_xml2
    # Map of [altRepGroup ids, node_name, parent node] from mods_ng_xml1 to mods_ng_xml2
    # The parent node is necessary because ids are unique for mods/relatedItem not entire document.
    @altrepgroup_ids = {}
    # Map of equivalent nodes with altRepGroup attributes.
    @altrepgroup_nodes = {}
    # Map of [nameTitleGroup ids, parent node] from mods_ng_xml1 to mods_ng_xml2
    # The parent node is necessary because ids are unique for mods/relatedItem not entire document.
    @nametitlegroup_ids = {}
    # Map of equivalent nodes with nameTitleGroup attributes.
    @nametitlegroup_nodes = {}
  end

  def equivalent_with_result?
    return Failure(diff) unless xml_equivalent?

    # Checks equivalence of altRepGroup attributes.
    return Failure(altrepgroup_diff) if altrepgroup_diff.present?

    # Checks equivalence of nameTitleGroup attributes.
    return Failure(nametitlegroup_diff) if nametitlegroup_diff.present?

    Success()
  end

  def equivalent?
    return false unless xml_equivalent?

    # Checks equivalence of altRepGroup attributes.
    return false if altrepgroup_diff.present?

    # Checks equivalence of nameTitleGroup attributes.
    return false if nametitlegroup_diff.present?

    true
  end

  private

  attr_reader :mods_ng_xml1, :mods_ng_xml2, :altrepgroup_ids, :altrepgroup_nodes, :nametitlegroup_ids, :nametitlegroup_nodes

  def xml_equivalent?
    @xml_equivalent ||= EquivalentXml.equivalent?(mods_ng_xml1, mods_ng_xml2) do |node1, node2|
      # Checks equivalence ignoring the nameTitleGroup and altRepGroup attributes.
      nodes_equivalent?(node1, node2)
    end
  end

  def nodes_equivalent?(node1, node2)
    norm_node1 = node1.dup
    norm_node2 = node2.dup
    if node1['altRepGroup']
      altrepgroup1 = norm_node1.delete('altRepGroup')
      altrepgroup2 = norm_node2.delete('altRepGroup')
    end

    if node1['nameTitleGroup']
      nametitlegroup1 = norm_node1.delete('nameTitleGroup')
      nametitlegroup2 = norm_node2.delete('nameTitleGroup')
    end

    # Returning nil means leave the equivalent result unchanged.
    # Returning if neither altRepGroup or nameTitleGroup attribute.
    return nil unless altrepgroup1 || nametitlegroup1

    # Check equiv without the altRepGroup and nameTitleGroup attributes.
    equiv = EquivalentXml.equivalent?(norm_node1, norm_node2)
    if equiv
      if altrepgroup1
        altrepgroup_ids[[altrepgroup1.value, node1.name, node1.parent]] = altrepgroup2.value if altrepgroup2
        altrepgroup_nodes[node1] = node2
      end
      if nametitlegroup1
        nametitlegroup_ids[[nametitlegroup1.value, node1.parent]] = nametitlegroup2.value if nametitlegroup2
        nametitlegroup_nodes[node1] = node2
      end
    end
    equiv
  end

  def diff
    element_diff = mods_nodes1.map do |mods_node1|
      next nil if has_equivalent_node?(mods_node1)

      Difference.new(mods_node1, find_closest_node(mods_node1))
    end.compact

    attr_diff = mods_ng_xml1.root.keys.map do |attr_key|
      next if mods_ng_xml1.root[attr_key] == mods_ng_xml2.root[attr_key]

      Difference.new(mods_ng_xml1.root[attr_key], mods_ng_xml2.root[attr_key])
    end.compact

    element_diff + attr_diff
  end

  def mods_nodes1
    @mods_nodes1 ||= mods_ng_xml1.root.xpath('mods:*', mods: Dor::DescMetadataDS::MODS_NS)
  end

  def mods_nodes2
    @mods_nodes2 ||= mods_ng_xml2.root.xpath('mods:*', mods: Dor::DescMetadataDS::MODS_NS)
  end

  def norm_mods_nodes2
    @norm_mods_nodes2 ||= mods_ng_xml2.root.xpath('mods:*', mods: Dor::DescMetadataDS::MODS_NS).map { |node| norm_node(node) }
  end

  def norm_node(node)
    new_node = node.deep_dup
    new_node.delete('altRepGroup')
    new_node.delete('nameTitleGroup')
    new_node
  end

  def mods_nodes2_without_equivalent
    @mods_nodes2_without_equivalent ||= mods_nodes2.select do |mods_node2|
      mods_nodes1.none? { |mods_node1| EquivalentXml.equivalent?(mods_node1, mods_node2) }
    end
  end

  def has_equivalent_node?(mods_node1)
    norm_mods_node1 = norm_node(mods_node1)
    norm_mods_nodes2.any? { |mods_node2| EquivalentXml.equivalent?(norm_mods_node1, mods_node2) }
  end

  def find_closest_node(mods_node1)
    mods_nodes2_with_same_tag = mods_nodes2_without_equivalent.select { |mods_node2| mods_node2.name == mods_node1.name }

    return nil if mods_nodes2_with_same_tag.empty?
    return mods_nodes2_with_same_tag.first if mods_nodes2_with_same_tag.size == 1

    distances = {}
    mods_nodes2_with_same_tag.each { |mods_node2| distances[distance(mods_node1, mods_node2)] = mods_node2 }

    distances[distances.keys.min]
  end

  def distance(mods_node1, mods_node2)
    set1 = Set.new(mods_node1.content.split(' '))
    set2 = Set.new((mods_node2.content.split(' ')))
    set1.difference(set2).size + set2.difference(set1).size
  end

  def altrepgroup_diff
    @altrepgroup_diff ||= altrepgroup_nodes.keys.map do |node1|
      node1_altrepgroup = node1['altRepGroup']
      node2 = altrepgroup_nodes[node1]
      node2_altrepgroup = node2 ? node2['altRepGroup'] : nil
      expected_node2_altrepgroup = altrepgroup_ids[[node1_altrepgroup, node1.name, node1.parent]]

      next nil if expected_node2_altrepgroup && expected_node2_altrepgroup == node2_altrepgroup

      Difference.new(node1, node2)
    end.compact
  end

  def nametitlegroup_diff
    @nametitlegroup_diff ||= nametitlegroup_nodes.keys.map do |node1|
      node1_nametitlegroup = node1['nameTitleGroup']
      node2 = nametitlegroup_nodes[node1]
      node2_nametitlegroup = node2 ? node2['nameTitleGroup'] : nil
      expected_node2_nametitlegroup = nametitlegroup_ids[[node1_nametitlegroup, node1.parent]]

      next nil if expected_node2_nametitlegroup && expected_node2_nametitlegroup == node2_nametitlegroup

      Difference.new(node1, node2)
    end.compact
  end
end
