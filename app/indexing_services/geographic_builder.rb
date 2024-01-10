# frozen_string_literal: true

class GeographicBuilder
  # @param [Array<Cocina::Models::Subject>] subjects
  # @return [Array<String>] the geographic values for Solr
  def self.build(subjects)
    new(subjects).build
  end

  def initialize(subjects)
    @subjects = Array(subjects)
  end

  def build
    extract_place_from_subjects(subjects)
  end

  def extract_place_from_subjects(local_subjects)
    (
      build_place_nodes(local_subjects.select { |node| node.type == 'place' }) +
      local_subjects.reject(&:type).flat_map do |subject|
        next extract_place_from_subjects(subject.parallelValue) if subject.parallelValue.present?

        build_place_nodes(Array(subject.structuredValue).select { |node| node.type == 'place' })
      end
    ).uniq
  end

  private

  attr_reader :subjects

  def build_place_nodes(nodes)
    Array(nodes).flat_map { |node| build_place(node) }
  end

  # @param [Cocina::Models::DescriptiveValue]
  def build_place(node)
    remove_trailing_punctuation(
      Array(node.value) +
      place_from_code(node) +
      build_hierarchical_subject(node) +
      Array(node.parallelValue).flat_map { |child| build_place(child) }
    )
  end

  # @return [Array<String>]
  def place_from_code(node)
    return [] unless node.code && node.source

    code = node.code.gsub(/[^\w-]/, '') # remove any punctuation (except dash).
    case node.source.code
    when 'marcgac'
      [Marc::Vocab::GeographicArea.fetch(code)]
    when 'marccountry'
      [Marc::Vocab::Country.fetch(code)]
    else
      []
    end
  rescue KeyError
    # Per Arcadia, halt HB notification until after data clean-up.
    # Honeybadger.notify("[DATA ERROR] Unable to find \"#{code}\" in authority \"#{node.source.code}\"")
    []
  end

  def build_hierarchical_subject(node)
    Array(node.structuredValue&.map(&:value).presence&.join(' '))
  end

  def remove_trailing_punctuation(strings)
    strings.map { |str| str.sub(%r{[ ,\\/;]+$}, '') }
  end
end
