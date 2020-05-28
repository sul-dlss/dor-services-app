# frozen_string_literal: true

module Dor
  class ServiceItem
    # @return [String] value with SIRSI/Symphony numeric catkey in it for specified object, or nil if none exists
    # this is a class level method so it can be used on aribtrary druids (e.g. collection the item is associated with) without having to instantiate the object
    # look in identityMetadata/otherId[@name='catkey']
    def self.get_ckey(object)
      object.catkey
    end

    def initialize(druid_obj)
      @druid_obj = druid_obj
    end

    # the ckey for the current object
    # @return [String] value with SIRSI/Symphony numeric catkey in it for specified object, or nil if none exists
    def ckey
      @druid_obj.catkey
    end

    # the previous ckeys for the current object
    # @return [Array] previous catkeys for the object in an array, empty array if none exist
    def previous_ckeys
      @druid_obj.previous_catkeys.reject(&:empty?)
    end

    # @return [String] value with object_type in it (nil if none found)
    # look in identityMetadata/objectType
    def object_type
      @druid_obj.object_type
    end

    # the barcode
    # @return [String] value with barcode in it (nil if none found)
    # look in identityMetadata/otherId name="barcode"
    def barcode
      @druid_obj.barcode
    end

    # the @id attribute of resource/file elements including extension
    # @return [String] thumbnail filename (nil if none found)
    def thumb
      @thumb ||= ERB::Util.url_encode(ThumbnailService.new(@druid_obj).thumb).presence unless @druid_obj.datastreams.nil?
    end

    # returns the first collection_id the object is contained in (if any)
    # @return [String] collection druid the item is in (blank if none)
    def collection_id
      @collection_id ||= @druid_obj.collections.empty? ? '' : @druid_obj.collections.first.id
    end

    # returns the name of the first collection the object is contained in (if any)
    # @return [String] first collection name the item is in (blank if none)
    def collection_name
      @collection_name ||= @druid_obj.collections.empty? ? '' : @druid_obj.collections.first.label
    end

    # returns the value of the content_type tag from admin tags service if it exists, else returns the value from contentMetadata object type
    # note, the content_type tag comes from value of the tag called "Process : Content Type"
    # @return [String] first collection name the item is in (blank if none)
    def content_type
      @content_type ||= if AdministrativeTags.content_type(pid: @druid_obj.id).empty?
                          @druid_obj.contentMetadata.contentType.first
                        else
                          AdministrativeTags.content_type(pid: @druid_obj.id).first
                        end
    end

    # returns the name of the project by examining the objects tags
    # @return [String] first project tag value if one exists (blank if none)
    def project_name
      @project_name ||= begin
        project_tag_id = 'Project : '
        content_tag = AdministrativeTags.for(pid: @druid_obj.id).select { |tag| tag.include?(project_tag_id) }
        content_tag.empty? ? '' : content_tag[0].gsub(project_tag_id, '').strip
      end
    end

    # returns the name of the goobiworkflow in the object by examining the objects tags
    # @return [String] first goobi workflow tag value if one exists (default from config if none)
    def goobi_workflow_name
      @goobi_workflow_name ||= begin
        dpg_workflow_tag_id = 'DPG : Workflow : '
        content_tag = AdministrativeTags.for(pid: @druid_obj.id).select { |tag| tag.include?(dpg_workflow_tag_id) }
        content_tag.empty? ? Settings.goobi.default_goobi_workflow_name : content_tag[0].split(':').last.strip
      end
    end

    # returns true or false depending if the specially defined goobi DPG ocr tag is present in the object
    # @return [boolean]
    def goobi_ocr_tag_present?
      @goobi_ocr_tag_present ||= begin
        dpg_goobi_ocr_tag = 'DPG : OCR : TRUE'
        AdministrativeTags.for(pid: @druid_obj.id).any? { |tag| tag.casecmp(dpg_goobi_ocr_tag).zero? } # case insensitive compare
      end
    end

    # returns an array of arrays, each element contains an array of [name, value] of DOR object tags in the format expected to pass to Goobi
    # the name of the tag is the first namespace part of the tag (before first colon), value of the tag is everything after this
    # @return [Array] of GoobiTag objects
    def goobi_tag_list
      AdministrativeTags.for(pid: @druid_obj.id).map do |tag|
        tag_split = tag.split(':', 2).map(&:strip) # only split on the first colon
        GoobiTag.new(name: tag_split[0], value: tag_split[1])
      end
    end

    private

    def title_or_label
      title_element = primary_mods_title_info_element
      return title_element.content.strip if title_element.respond_to?(:content) && title_element.content.present?

      @druid_obj.label
    end

    def primary_mods_title_info_element
      return nil unless @druid_obj.datastreams['descMetadata']

      title_info = @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo', mods: 'http://www.loc.gov/mods/v3').first

      title_info
    end
  end
end
