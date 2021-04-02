# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms a license URI into the xml to be written on a Fedora 3 datastream.
    class License
      Resource = Struct.new(:code, :label)
      # These codes are the only codes accepted by DefaultObjectRightsDS#use_license=
      # so we can't just add to this list without updating that method.
      # https://github.com/sul-dlss/dor-services/blob/main/lib/dor/services/creative_commons_license_service.rb
      # https://github.com/sul-dlss/dor-services/blob/main/lib/dor/services/open_data_license_service.rb
      LICENSE_CODES = {
        nil => Resource.new(nil, nil),
        Cocina::FromFedora::Access::NONE_LICENSE_URI => Resource.new('none', 'no Creative Commons (CC) license'), # Only used in some legacy ETDs.
        'https://creativecommons.org/share-your-work/public-domain/cc0/' => Resource.new('cc0', 'No Rights Reserved'),
        'https://creativecommons.org/licenses/by/3.0/' => Resource.new('by', 'Attribution 3.0 Unported'),
        'https://creativecommons.org/licenses/by-sa/3.0/' => Resource.new('by-sa', 'Attribution Share Alike 3.0 Unported'),
        'https://creativecommons.org/licenses/by-nd/3.0/' => Resource.new('by-nd', 'Attribution No Derivatives 3.0 Unported'),
        'https://creativecommons.org/licenses/by-nc/3.0/' => Resource.new('by-nc', 'Attribution Non-Commercial 3.0 Unported'),
        'https://creativecommons.org/licenses/by-nc-sa/3.0/' => Resource.new('by-nc-sa', 'Attribution Non-Commercial Share Alike 3.0 Unported'),
        'https://creativecommons.org/licenses/by-nc-nd/3.0/' => Resource.new('by-nc-nd', 'Attribution Non-Commercial, No Derivatives 3.0 Unported'),
        'https://creativecommons.org/publicdomain/mark/1.0/' => Resource.new('pdm', 'Public Domain Mark 1.0'),
        'http://opendatacommons.org/licenses/pddl/1.0/' => Resource.new('pddl', 'Open Data Commons Public Domain Dedication and License 1.0'),
        'http://opendatacommons.org/licenses/by/1.0/' => Resource.new('odc-by', 'Open Data Commons Attribution License 1.0'),
        'http://opendatacommons.org/licenses/odbl/1.0/' => Resource.new('odc-odbl', 'Open Data Commons Open Database License 1.0')
      }.freeze

      def self.update(datastream, uri)
        new(datastream, uri).update
      end

      def initialize(datastream, uri)
        @datastream = datastream
        @uri = uri
      end

      def update
        initialize_license_fields!
        license = LICENSE_CODES.fetch(uri)

        if uri.blank?
          clear_licenses
        elsif uri.start_with?('https://creativecommons.org/')
          assign_creative_commons_license(uri, license)
        elsif uri.start_with?('http://opendatacommons.org/')
          assign_open_data_commons_license(uri, license)
        elsif uri == Cocina::FromFedora::Access::NONE_LICENSE_URI
          datastream.creative_commons = license.code
          datastream.creative_commons.uri = ''
          datastream.creative_commons_human = license.label
          datastream.open_data_commons = ''
          datastream.open_data_commons.uri = ''
          datastream.open_data_commons_human = ''
        else
          raise ArgumentError, "'#{uri}' is not a valid license code"
        end
      end

      private

      attr_reader :uri, :datastream

      def assign_open_data_commons_license(uri, license)
        datastream.open_data_commons = license.code
        datastream.open_data_commons.uri = uri
        datastream.open_data_commons_human = license.label
        datastream.creative_commons = ''
        datastream.creative_commons.uri = ''
        datastream.creative_commons_human = ''
      end

      def assign_creative_commons_license(uri, license)
        datastream.creative_commons = license.code
        datastream.creative_commons.uri = uri
        datastream.creative_commons_human = license.label
        datastream.open_data_commons = ''
        datastream.open_data_commons.uri = ''
        datastream.open_data_commons_human = ''
      end

      def clear_licenses
        datastream.creative_commons = ''
        datastream.creative_commons.uri = ''
        datastream.creative_commons_human = ''
        datastream.open_data_commons = ''
        datastream.open_data_commons.uri = ''
        datastream.open_data_commons_human = ''
      end

      def use_field
        datastream.find_by_terms(:use).first # rubocop:disable Rails/DynamicFindBy
      end

      def initialize_field!(field_name, root_term = datastream.ng_xml.root)
        datastream.add_child_node(root_term, field_name)
      end

      def initialize_license_fields!
        initialize_field!(:use) if use_field.blank?
        initialize_field!(:creative_commons, use_field) if datastream.creative_commons.blank?
        initialize_field!(:open_data_commons, use_field) if datastream.open_data_commons.blank?
      end
    end
  end
end
