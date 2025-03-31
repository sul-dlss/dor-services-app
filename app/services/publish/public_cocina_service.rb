# frozen_string_literal: true

module Publish
  # Filters out the non-public parts of cocina for publishing to purl
  class PublicCocinaService
    def self.create(cocina)
      new(cocina).build
    end

    def initialize(cocina)
      @cocina = cocina
    end

    # update the label to match what is in the description.title (used by sul-embed and searchworks_traject_indexer)
    # remove any file that is not published
    # remove any file_set that doesn't have at least one published file
    # remove partOfProject (similar to how we remove tags from identityMetadata)
    def build # rubocop:disable Metrics/AbcSize
      label = Cocina::Models::Builders::TitleBuilder.build(cocina.description.title)
      if cocina.dro?
        cocina.new(label:, structural: build_structural, administrative: build_administrative)
      elsif cocina.collection?
        cocina.new(label:, administrative: build_administrative)
      else
        raise "unexpected call to PublicCocinaService.build for #{cocina.externalIdentifier}"
      end
    end

    private

    attr_reader :cocina

    # remove partOfProject (similar to how we remove tags from identityMetadata)
    # and rewrite release tags with the tags from the collection.
    def build_administrative
      Cocina::Models::Administrative.new(cocina.administrative.to_h.except(:partOfProject))
    end

    def build_structural # rubocop:disable Metrics/AbcSize
      return {} unless cocina.structural

      file_sets = Array(cocina.structural.contains)
      new_file_sets = file_sets.filter_map do |fs|
        files = fs.structural.contains.select { |file| file.administrative.publish }
        next if files.empty?

        new_file_set_structural = fs.structural.new(contains: files)

        fs.new(structural: new_file_set_structural)
      end
      cocina.structural.new(contains: new_file_sets)
    end
  end
end
