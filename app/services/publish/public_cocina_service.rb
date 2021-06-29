# frozen_string_literal: true

module Publish
  # Filters out the non-public parts of cocina for publishing to purl
  class PublicCocinaService
    def self.create(item)
      cocina = Cocina::Mapper.build(item)
      new(cocina).build
    end

    def initialize(cocina)
      @cocina = cocina
    end

    # remove any file that is not published
    # remove any file_set that doesn't have at least one published file
    def build
      return cocina.to_json unless cocina.dro?

      file_sets = Array(cocina.structural.contains)
      new_file_sets = file_sets.filter_map do |fs|
        files = fs.structural.contains.select { |file| file.administrative.publish }
        next if files.empty?

        new_file_set_structural = fs.structural.new(contains: files)
        fs.new(structural: new_file_set_structural)
      end
      new_structural = cocina.structural.new(contains: new_file_sets)
      cocina.new(structural: new_structural).to_json
    end

    private

    attr_reader :cocina
  end
end
