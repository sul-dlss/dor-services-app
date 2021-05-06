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
    #
    # def last_element
    #   public_mods.root.element_children.last
    # end

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
      rights.xpath("//use/machine[#{ci_compare('type', 'creativecommons')}]").each do |lic_type|
        next if /none/i.match?(lic_type.text)

        lic_text = rights.at_xpath("//use/human[#{ci_compare('type', 'creativecommons')}]").text.strip
        next if lic_text.empty?

        new_text = "CC #{lic_type.text}: #{lic_text}"
        add_access_condition(new_text, 'license')
      end

      rights.xpath("//use/machine[#{ci_compare('type', 'opendatacommons')}]").each do |lic_type|
        next if /none/i.match?(lic_type.text)

        lic_text = rights.at_xpath("//use/human[#{ci_compare('type', 'opendatacommons')}]").text.strip
        next if lic_text.empty?

        new_text = "ODC #{lic_type.text}: #{lic_text}"
        add_access_condition(new_text, 'license')
      end
    end

    def add_access_condition(text, type)
      last_element.add_next_sibling public_mods.create_element('accessCondition', text, type: type)
    end

    def last_element
      public_mods.root.element_children.last
    end

    # Builds case-insensitive xpath translate function call that will match the attribute to a value
    def ci_compare(attribute, value)
      "translate(
        @#{attribute},
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ',
        'abcdefghijklmnopqrstuvwxyz'
       ) = '#{value}' "
    end
  end
end
