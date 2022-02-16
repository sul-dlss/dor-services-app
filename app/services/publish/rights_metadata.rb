# frozen_string_literal: true

module Publish
  # Exports the rightsMetadata XML that is sent to purl.stanford.edu
  class RightsMetadata
    attr_reader :cocina_object

    # @param [Cocina::Models::DRO, Cocina::Models::Collection] public_cocina a cocina object stripped of non-public data
    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    # @return [Nokogiri::Xml] the original xml with the legacy style rights added so that the description can be displayed.
    def create
      return create_collection_xml if cocina_object.collection?

      create_dro_xml
    end

    private

    def create_collection_xml
      <<~XML
        <rightsMetadata>
          <access type="discover">
            <machine>
              <#{collection_access} />
            </machine>
          </access>
          <access type="read">
            <machine>
              <#{collection_access} />
            </machine>
          </access>
          #{use}
          #{copyright}
        </rightsMetadata>
      XML
    end

    def collection_access
      cocina_object.access.access == 'dark' ? 'none' : cocina_object.access.access
    end

    def create_dro_xml
      <<~XML
        <rightsMetadata>
          #{discover}
          #{read}
          #{read_location}
          #{read_world_no_download}
          #{use}
          #{copyright}
        </rightsMetadata>
      XML
    end

    def discover
      <<~XML
        <access type="discover">
          <machine>
            <#{access} />
          </machine>
        </access>
      XML
    end

    def access
      return 'none' if %w[dark none].include?(cocina_object.access.access)

      'world'
    end

    def read
      return if location_based?

      <<~XML
        <access type="read">
          <machine>
            #{download}
            #{release_date}
          </machine>
        </access>
      XML
    end

    def location_based?
      return true if cocina_object.access.access == 'location-based'
      return true if [cocina_object.access.access, cocina_object.access.download] == %w[world location-based]

      false
    end

    def read_location
      return unless [cocina_object.access.access, cocina_object.access.download].include? 'location-based'

      <<~XML
        <access type="read">
          <machine>
            #{read_location_based}
          </machine>
        </access>
      XML
    end

    def read_location_based
      rule = 'rule="no-download"' if cocina_object.access.download == 'none'
      "<location #{rule}>#{cocina_object.access.readLocation}</location>" if cocina_object.access.readLocation
    end

    def read_world_no_download
      return unless cocina_object.access.access == 'world'
      return unless %w[stanford location-based].include? cocina_object.access.download

      '<access type="read"><machine><world rule="no-download" /></machine></access>'
    end

    def download
      return cdl if cocina_object.access.controlledDigitalLending
      return '<group>stanford</group>' if cocina_object.access.download == 'stanford'
      return '<group rule="no-download">stanford</stanford>' if cocina_object.access.access == 'stanford' && cocina_object.access.download != 'stanford'

      "<#{cocina_object.access.download} />"
    end

    def cdl
      '<cdl><group rule="no-download">stanford</group></cdl>'
    end

    def release_date
      return unless cocina_object.access.embargo

      "<embargoReleaseDate>#{cocina_object.access.embargo.releaseDate.utc.iso8601}</embargoReleaseDate>"
    end

    def use
      "<use>#{use_statement}#{license}</use>"
    end

    def use_statement
      return '<human type="useAndReproduction" />' unless cocina_object.access.useAndReproductionStatement

      "<human type=\"useAndReproduction\">#{cocina_object.access.useAndReproductionStatement}</human>"
    end

    def license
      return '<license />' unless cocina_object.access.license

      "<license>#{cocina_object.access.license}</license>"
    end

    def copyright
      "<copyright>#{copyright_statement}</copyright>"
    end

    def copyright_statement
      return '<human />' unless cocina_object.access.copyright

      "<human>#{cocina_object.access.copyright}</human>"
    end
  end
end
