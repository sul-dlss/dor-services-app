# frozen_string_literal: true

module Publish
  # Exports the rightsMetadata XML that is sent to purl.stanford.edu
  class RightsMetadata
    attr_reader :original, :release_date

    # @param [Nokogiri::XML] original
    # @param [String] release_date the embargo release date if one is set, otherwise send nil.
    def initialize(original, release_date:)
      @original = original
      @release_date = release_date
    end

    # @return [Nokogiri::Xml] the original xml with the legacy style rights added so that the description can be displayed.
    def create
      add_release_date
      original.clone
    end

    private

    def add_release_date
      return unless release_date

      read_machine_node = original.xpath('/rightsMetadata/access[@type="read"]/machine').first
      date_node = read_machine_node.xpath('./embargoReleaseDate').first || read_machine_node.add_child('<embargoReleaseDate />').first
      date_node.content = release_date
    end
  end
end
