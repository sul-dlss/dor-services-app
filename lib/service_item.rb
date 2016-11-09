module Dor
  class ServiceItem
    # @return [String] value with SIRSI/Symphony numeric catkey in it for specified object, or nil if none exists
    # look in identityMetadata/otherId[@name='catkey']
    def self.get_ckey(object)
      unless object.datastreams.nil? || object.datastreams['identityMetadata'].nil?
        if object.datastreams['identityMetadata'].ng_xml
          node = object.identityMetadata.ng_xml.at_xpath("//identityMetadata/otherId[@name='catkey']")
        end
      end
      node.content if node && node.content.present?
    end

    def initialize(druid_obj)
      @druid_obj = druid_obj
      @druid_id = @druid_obj.remove_druid_prefix
    end

    # the ckey for the current object
    # @return [String] value with SIRSI/Symphony numeric catkey in it for specified object, or nil if none exists
    def ckey
      self.class.get_ckey(@druid_obj)
    end

    # @return [String] value with object_type in it, or empty x subfield if none exists
    # look in identityMetadata/objectType
    def object_type
      @object_type ||= begin
        node = @druid_obj.datastreams['identityMetadata'].ng_xml.at_xpath('//identityMetadata/objectType')
        node.content unless node.nil?
      end
    end

    # the barcode
    # @return [String] value with barcode in it, or empty x subfield if none exists
    # look in identityMetadata/otherId name="barcode"
    def barcode
      @barcode ||= begin
        node = @druid_obj.datastreams['identityMetadata'].ng_xml.at_xpath("//identityMetadata/otherId[@name='barcode']")
        node.content unless node.nil?
      end
    end

    # the @id attribute of resource/file elements including extension
    # @return [String] thumbnail filename (nil if none found)
    def thumb
      @druid_obj.encoded_thumb unless @druid_obj.datastreams.nil?
    end

    # returns the first collection_id the object is contained in (if any)
    # @return [String] collection druid the item is in (blank if none)
    def collection_id
      @druid_obj.collections.empty? ? '' : @druid_obj.collections.first.id
    end

    # returns the name of the first collection the object is contained in (if any)
    # @return [String] first collection name the item is in (blank if none)
    def collection_name
      @druid_obj.collections.empty? ? '' : @druid_obj.collections.first.label
    end

    # returns the value of the content_type_tag from dor services if it exists, else returns the value from contentMetadata object type
    # note, the content_type_tag comes from value of the tag called "Process : Content Type"
    # @return [String] first collection name the item is in (blank if none)
    def content_type
      if @druid_obj.content_type_tag.empty?
        node = @druid_obj.datastreams['contentMetadata'].ng_xml.at_xpath('//contentMetadata/@type')
        node.blank? ? '' : node.content
      else
        @druid_obj.content_type_tag
      end
    end

    # returns the name of the project by examining the objects tags
    # @return [String] first project tag value if one exists (blank if none)
    def project_name
      project_tag_id = 'Project : '
      content_tag = @druid_obj.tags.select { |tag| tag.include?(project_tag_id) }
      content_tag.empty? ? '' : content_tag[0].gsub(project_tag_id, '').strip
    end

    # returns the name of the goobiworkflow in the object by examining the objects tags
    # @return [String] first goobi workflow tag value if one exists (default from config if none)
    def goobi_workflow_name
      dpg_workflow_tag_id = 'DPG : Workflow : '
      content_tag = @druid_obj.tags.select { |tag| tag.include?(dpg_workflow_tag_id) }
      content_tag.empty? ? Dor::Config.goobi.default_goobi_workflow_name : content_tag[0].split(':').last.strip
    end
  end
end
