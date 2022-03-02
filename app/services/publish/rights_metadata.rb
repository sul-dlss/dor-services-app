# frozen_string_literal: true

module Publish
  # Exports the rightsMetadata XML that is sent to purl.stanford.edu
  # rubocop:disable Metrics/ClassLength
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
          #{read(cocina_object.access)}
          #{read_world_no_download}
          #{read_content}
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

    def read(object_access, filename = nil)
      return read_location(object_access, filename) if location_based?(object_access)

      file = filename ? "<file>#{filename}</file>" : nil

      <<~XML
        <access type="read">
          #{file}
          <machine>
            #{download(object_access)}
            #{release_date}
          </machine>
        </access>
        #{read_location(object_access, filename) if object_access.download == 'location-based'}
      XML
    end

    def location_based?(object_access)
      return true if object_access.access == 'location-based'
      return true if [object_access.access, object_access.download] == %w[world location-based]

      false
    end

    def read_location(object_access, filename)
      file = filename ? "<file>#{filename}</file>" : nil

      <<~XML
        <access type="read">
          #{file}
          <machine>
            #{read_location_based(object_access)}
          </machine>
        </access>
      XML
    end

    def read_location_based(object_access)
      rule = 'rule="no-download"' if object_access.download == 'none'
      "<location #{rule}>#{object_access.readLocation}</location>" if object_access.readLocation
    end

    def read_world_no_download
      return unless cocina_object.access.access == 'world'
      return unless %w[stanford location-based].include? cocina_object.access.download

      '<access type="read"><machine><world rule="no-download" /></machine></access>'
    end

    def read_content
      return unless cocina_object.structural

      access_nodes = []
      cocina_object.structural.contains.each do |file_set|
        next unless file_set.structural

        file_set.structural.contains.each do |file|
          next if file.access.download == 'world'

          access_nodes.push(read(file.access, file.filename))
        end
      end

      access_nodes.join("\n")
    end

    def download(object_access)
      return cdl if object_access.controlledDigitalLending
      return '<group>stanford</group>' if object_access.download == 'stanford'
      return '<group rule="no-download">stanford</stanford>' if object_access.access == 'stanford' && object_access.download != 'stanford'
      return '<world rule="no-download" />' if object_access.access == 'world' && object_access.download == 'none'

      "<#{object_access.download} />"
    end

    def cdl
      '<cdl><group rule="no-download">stanford</group></cdl>'
    end

    def release_date
      return unless cocina_object.access.embargo

      "<embargoReleaseDate>#{cocina_object.access.embargo.releaseDate.utc.iso8601}</embargoReleaseDate>"
    end

    def use
      return unless use_statement || license

      "<use>#{use_statement}#{license}</use>"
    end

    def use_statement
      "<human type=\"useAndReproduction\">#{cocina_object.access.useAndReproductionStatement}</human>" if cocina_object.access.useAndReproductionStatement
    end

    def license
      "<license>#{cocina_object.access.license}</license>" if cocina_object.access.license
    end

    def copyright
      "<copyright>#{copyright_statement}</copyright>" if copyright_statement
    end

    def copyright_statement
      "<human>#{cocina_object.access.copyright}</human>" if cocina_object.access.copyright
    end
  end
  # rubocop:enable Metrics/ClassLength
end
