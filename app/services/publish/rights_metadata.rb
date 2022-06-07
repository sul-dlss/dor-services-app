# frozen_string_literal: true

module Publish
  # Exports the rightsMetadata XML that is sent to purl.stanford.edu
  class RightsMetadata
    attr_reader :cocina_object, :release_date

    # @param [Cocina::Models::DRO, Cocina::Models::Collection] public_cocina a cocina object stripped of non-public data
    def initialize(cocina_object, release_date)
      @cocina_object = cocina_object
      @release_date = release_date
    end

    # @return [Nokogiri::Xml] the original xml with the legacy style rights added so that the description can be displayed.
    def create
      structural = cocina_object.structural || nil if cocina_object.respond_to?(:structural)
      cocina_access = Nokogiri::XML(Cocina::ToXml::AccessGenerator.generate(root: Nokogiri::XML('<rightsMetadata/>').root,
                                                                            access: cocina_object.access,
                                                                            structural:))
      add_release_date(cocina_access) if release_date
      add_use_statement(cocina_access) if cocina_object.access.useAndReproductionStatement
      add_copyright_statement(cocina_access) if cocina_object.access.copyright

      cocina_access.root
    end

    private

    def add_release_date(cocina_access)
      read_machine_node = cocina_access.xpath('/rightsMetadata/access[@type="read"]/machine').first
      date_node = read_machine_node.xpath('./embargoReleaseDate').first || read_machine_node.add_child('<embargoReleaseDate />').first
      date_node.content = release_date
    end

    def add_use_statement(cocina_access)
      use_node = cocina_access.root.add_child('<use />').first
      use_human_node = use_node.add_child('<human type="useAndReproduction" />').first
      use_human_node.content = cocina_object.access.useAndReproductionStatement
      use_license_node = use_node.add_child('<license />').first
      use_license_node.content = cocina_object.access.license
    end

    def add_copyright_statement(cocina_access)
      copyright_node = cocina_access.root.add_child('<copyright />').first
      use_human_node = copyright_node.add_child('<human />').first
      use_human_node.content = cocina_object.access.copyright
    end
  end
end
