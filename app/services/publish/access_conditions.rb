# frozen_string_literal: true

module Publish
  # Add accessConditions to the public MODS that we publish to PURL.
  # These are derived from the rightsMetadata and are consumed by the
  # Searchworks item view via the mods_display gem.
  class AccessConditions
    def self.add(public_mods:, rights_md:)
      new(public_mods: public_mods, rights_md: rights_md).add
    end

    def initialize(public_mods:, rights_md:)
      @public_mods = public_mods
      @rights_md = rights_md
    end

    def add
      clear_existing_access_conditions
      add_use_statement
      add_copyright
      add_license
    end

    private

    attr_reader :rights_md, :public_mods

    def rights
      @rights ||= rights_md.ng_xml
    end

    # clear out any existing accessConditions
    def clear_existing_access_conditions
      public_mods.xpath('//mods:accessCondition', 'mods' => 'http://www.loc.gov/mods/v3').each(&:remove)
    end

    def add_use_statement
      rights.xpath('//use/human[@type="useAndReproduction"]').each do |use|
        txt = use.text.strip
        next if txt.empty?

        add_access_condition(txt, 'useAndReproduction')
      end
    end

    def add_copyright
      rights.xpath('//copyright/human[@type="copyright"]').each do |cr|
        txt = cr.text.strip
        next if txt.empty?

        add_access_condition(txt, 'copyright')
      end
    end

    def add_license
      return unless license?

      # Add the xlink namespace in case it doesn't exist.  Many items that were
      # Registered via dor-services-app do not because this namespace was not
      # configured here:
      # https://github.com/sul-dlss/dor-services/blob/ef7cd8c8d787e4b9781e5d00282d1d112d0e1f4f/lib/dor/datastreams/desc_metadata_ds.rb#L9-L14
      # We use this namespace when we add accessCondition
      public_mods.root.add_namespace_definition 'xlink', 'http://www.w3.org/1999/xlink'

      last_element.add_next_sibling public_mods.create_element('accessCondition', license.description,
                                                               type: 'license', 'xlink:href' => license.uri)
    end

    def license
      @license ||= License.new(url: license_url)
    rescue License::LegacyLicenseError
      Honeybadger.notify("[DATA ERROR] #{license_url} is not a supported license")
      if license_url.include?('creativecommons.org')
        # Try to find a workable license:
        @license = License.new(url: "#{license_url}legalcode")
      end
    end

    def license?
      license_url.present?
    end

    # Try each way, from most prefered to least preferred to get the license
    def license_url
      license_url_from_node || url_from_attribute || url_from_code
    end

    # This is the most modern way of determining what license to use.
    def license_url_from_node
      rights.at_xpath('//use/license').try(:text).presence
    end

    # This is a slightly older way, but it can differentiate between CC 3.0 and 4.0 licenses
    def url_from_attribute
      return unless machine_node

      machine_node['uri'].presence
    end

    # This is the most legacy and least preferred way, because it only handles out of data license versions
    def url_from_code
      type, code = machine_readable_license
      return unless type && code.present?

      case type.to_s
      when 'creativeCommons'
        case code
        when 'pdm'
          'https://creativecommons.org/publicdomain/mark/1.0/'
        when 'none'
          nil
        else
          "https://creativecommons.org/licenses/#{code}/3.0/legalcode"
        end
      when 'openDataCommons'
        code = code.delete_prefix('odc-')
        case code
        when 'none'
          nil
        when 'pddl', 'by', 'odbl'
          "https://opendatacommons.org/licenses/#{code}/1-0/"
        end
      end
    end

    def machine_readable_license
      [machine_node.attribute('type'), machine_node.text] if machine_node
    end

    def machine_node
      @machine_node ||= rights.at_xpath('//use/machine[@type="openDataCommons" or @type="creativeCommons"]')
    end

    def add_access_condition(text, type)
      last_element.add_next_sibling public_mods.create_element('accessCondition', text, type: type)
    end

    def last_element
      public_mods.root.element_children.last
    end
  end
end
