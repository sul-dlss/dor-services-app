# frozen_string_literal: true

module Dor
  class ServiceItem
    def initialize(druid_obj)
      @druid_obj = druid_obj
    end

    # the previous ckeys for the current object
    # @return [Array] previous catkeys for the object in an array, empty array if none exist
    def previous_ckeys
      @druid_obj.previous_catkeys.reject(&:empty?)
    end

    # the @id attribute of resource/file elements including extension
    # @return [String] thumbnail filename (nil if none found)
    def thumb
      @thumb ||= ERB::Util.url_encode(ThumbnailService.new(@druid_obj).thumb).presence unless @druid_obj.datastreams.nil?
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

    private

    def primary_mods_title_info_element
      return nil unless @druid_obj.datastreams['descMetadata']

      title_info = @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo', mods: 'http://www.loc.gov/mods/v3').first

      title_info
    end
  end
end
