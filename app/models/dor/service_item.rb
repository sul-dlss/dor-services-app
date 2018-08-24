module Dor
  class ServiceItem
    # @return [String] value with SIRSI/Symphony numeric catkey in it for specified object, or nil if none exists
    # this is a class level method so it can be used on aribtrary druids (e.g. collection the item is associated with) without having to instantiate the object
    # look in identityMetadata/otherId[@name='catkey']
    def self.get_ckey(object)
      return nil unless identity_metadata?(object)
      node = object.identityMetadata.ng_xml.at_xpath("//identityMetadata/otherId[@name='catkey']")
      node.content if node && node.content.present?
    end

    def self.identity_metadata?(object)
      object.datastreams && object.datastreams['identityMetadata'] && object.datastreams['identityMetadata'].ng_xml
    end

    def initialize(druid_obj)
      @druid_obj = druid_obj
      @druid_id = @druid_obj.remove_druid_prefix
      @dra_object = druid_obj.rightsMetadata.dra_object
    end

    # the ckey for the current object
    # @return [String] value with SIRSI/Symphony numeric catkey in it for specified object, or nil if none exists
    def ckey
      @ckey ||= self.class.get_ckey(@druid_obj)
    end

    # the previous ckeys for the current object
    # @return [Array] previous catkeys for the object in an array, empty array if none exist
    def previous_ckeys
      @previous_ckeys ||= if self.class.identity_metadata?(@druid_obj)
                            @druid_obj.identityMetadata.ng_xml.xpath("//identityMetadata/otherId[@name='previous_catkey']").map(&:content).reject(&:empty?)
                          else
                            []
                          end
    end

    # @return [String] value with object_type in it (nil if none found)
    # look in identityMetadata/objectType
    def object_type
      @object_type ||= begin
        node = @druid_obj.datastreams['identityMetadata'].ng_xml.at_xpath('//identityMetadata/objectType')
        node.content unless node.nil?
      end
    end

    # the barcode
    # @return [String] value with barcode in it (nil if none found)
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
      @thumb ||= @druid_obj.encoded_thumb unless @druid_obj.datastreams.nil?
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

    # returns the value of the content_type_tag from dor services if it exists, else returns the value from contentMetadata object type
    # note, the content_type_tag comes from value of the tag called "Process : Content Type"
    # @return [String] first collection name the item is in (blank if none)
    def content_type
      @content_type ||= if @druid_obj.content_type_tag.empty?
                          node = @druid_obj.datastreams['contentMetadata'].ng_xml.at_xpath('//contentMetadata/@type')
                          node.blank? ? '' : node.content
                        else
                          @druid_obj.content_type_tag
                        end
    end

    # returns the name of the project by examining the objects tags
    # @return [String] first project tag value if one exists (blank if none)
    def project_name
      @project_name ||= begin
        project_tag_id = 'Project : '
        content_tag = @druid_obj.tags.select { |tag| tag.include?(project_tag_id) }
        content_tag.empty? ? '' : content_tag[0].gsub(project_tag_id, '').strip
      end
    end

    # returns the name of the goobiworkflow in the object by examining the objects tags
    # @return [String] first goobi workflow tag value if one exists (default from config if none)
    def goobi_workflow_name
      @goobi_workflow_name ||= begin
        dpg_workflow_tag_id = 'DPG : Workflow : '
        content_tag = @druid_obj.tags.select { |tag| tag.include?(dpg_workflow_tag_id) }
        content_tag.empty? ? Dor::Config.goobi.default_goobi_workflow_name : content_tag[0].split(':').last.strip
      end
    end

    # returns true or false depending if the specially defined goobi DPG ocr tag is present in the object
    # @return [boolean]
    def goobi_ocr_tag_present?
      @goobi_ocr_tag_present ||= begin
        dpg_goobi_ocr_tag = 'DPG : OCR : TRUE'
        @druid_obj.tags.any? { |tag| tag.casecmp(dpg_goobi_ocr_tag).zero? } # case insensitive compare
      end
    end

    # returns an array of arrays, each element contains an array of [name, value] of DOR object tags in the format expected to pass to Goobi
    # the name of the tag is the first namespace part of the tag (before first colon), value of the tag is everything after this
    # @return [Array]
    def goobi_tag_list
      @druid_obj.tags.map do |tag|
        tag_split = tag.split(':', 2).map(&:strip) # only split on the first colon
        [tag_split[0], tag_split[1]]
      end
    end
  end
end
