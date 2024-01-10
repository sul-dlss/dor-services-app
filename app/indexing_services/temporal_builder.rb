# frozen_string_literal: true

class TemporalBuilder
  # @param [Array<Cocina::Models::Subject>] subjects
  # @return [Array<String>] the temporal values for Solr
  def self.build(subjects)
    new(subjects).build
  end

  def initialize(subjects)
    @subjects = Array(subjects)
  end

  def build
    extract_temporal_from_subjects(subjects)
  end

  def extract_temporal_from_subjects(local_subjects)
    (
      build_temporal_nodes(local_subjects.select { |node| node.type == 'time' }) +
      local_subjects.reject(&:type).flat_map do |subject|
        next extract_temporal_from_subjects(subject.parallelValue) if subject.parallelValue.present?

        build_temporal_nodes(Array(subject.structuredValue).select { |node| node.type == 'time' })
      end
    ).uniq
  end

  private

  attr_reader :subjects

  def build_temporal_nodes(nodes)
    Array(nodes).flat_map { |node| build_temporal(node) }
  end

  # @param [Cocina::Models::DescriptiveValue]
  def build_temporal(node)
    remove_trailing_punctuation(
      Array(node.value) +
      Array(node.structuredValue).map(&:value) +
      Array(node.parallelValue).flat_map { |child| build_temporal(child) }
    )
  end

  def remove_trailing_punctuation(strings)
    strings.map { |str| str.sub(%r{[ ,\\/;]+$}, '') }
  end
end
