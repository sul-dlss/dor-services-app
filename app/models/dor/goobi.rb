# frozen_string_literal: true

module Dor
  # This class passes data to the Goobi server using a custom XML message that was developed by Intranda
  class Goobi
    SERVER_ERROR_STATUSES = (500...600).freeze
    class ServerError < StandardError; end

    # Any status that is a 500 or greater and timeouts
    RETRIABLE_EXCEPTIONS = [ServerError,
                            Errno::ETIMEDOUT,
                            Faraday::TimeoutError,
                            Faraday::RetriableResponse].freeze

    def initialize(cocina_obj)
      @cocina_obj = cocina_obj
    end

    def register
      with_retries(max_tries: Settings.goobi.max_tries,
                   base_sleep_seconds: Settings.goobi.base_sleep_seconds,
                   max_sleep_seconds: Settings.goobi.max_sleep_seconds,
                   rescue: RETRIABLE_EXCEPTIONS) do |_attempt|
        response = Faraday.post(Settings.goobi.url, xml_request, 'Content-Type' => 'application/xml')
        # When we upgrade to Faraday 1.0, we can rely on Faraday::ServerError
        raise ServerError, status: response.status, body: response.body if SERVER_ERROR_STATUSES.include?(response.status)

        response
      end
    end

    private

    attr_reader :cocina_obj

    # We send all tags to Goobi, but "DPG : Workflow : xxx" is the one tag that Goobi uses
    def goobi_xml_tags
      goobi_tag_list.map(&:to_xml).join
    end

    def xml_request
      <<-END
        <stanfordCreationRequest>
            <objectId>#{cocina_obj.externalIdentifier}</objectId>
            <objectType>item</objectType>
            <sourceID>#{source_id&.encode(xml: :text)}</sourceID>
            <title>#{title_or_label.encode(xml: :text)}</title>
            <contentType>#{content_type}</contentType>
            <project>#{project_name.encode(xml: :text)}</project>
            <catkey>#{catkey}</catkey>
            <barcode>#{barcode}</barcode>
            <collectionId>#{collection_id}</collectionId>
            <collectionName>#{collection_name.encode(xml: :text)}</collectionName>
            <sdrWorkflow>#{Settings.goobi.dpg_workflow_name}</sdrWorkflow>
            <goobiWorkflow>#{goobi_workflow_name}</goobiWorkflow>
            <ocr>#{goobi_ocr_tag_present?}</ocr>
            <tags>#{goobi_xml_tags}</tags>
        </stanfordCreationRequest>
      END
    end

    # returns the name of the goobiworkflow in the object by examining the objects tags
    # @return [String] first goobi workflow tag value if one exists (default from config if none)
    def goobi_workflow_name
      @goobi_workflow_name ||= begin
        dpg_workflow_tag_id = 'DPG : Workflow : '
        content_tag = AdministrativeTags.for(pid: cocina_obj.externalIdentifier).select { |tag| tag.include?(dpg_workflow_tag_id) }
        content_tag.empty? ? Settings.goobi.default_goobi_workflow_name : content_tag[0].split(':').last.strip
      end
    end

    def catkey
      cocina_obj.identification&.catalogLinks&.filter { |link| link.catalog == 'symphony' }&.first&.catalogRecordId
    end

    def barcode
      cocina_obj.identification&.barcode
    end

    def source_id
      cocina_obj.identification&.sourceId
    end

    # returns the value of the content_type tag from admin tags service if it exists, else returns the value from contentMetadata object type
    # note, the content_type tag comes from value of the tag called "Process : Content Type"
    # @return [String] first collection name the item is in (blank if none)
    def content_type
      if AdministrativeTags.content_type(pid: cocina_obj.externalIdentifier).empty?
        Cocina::ToFedora::ContentType.map(cocina_obj.type)
      else
        AdministrativeTags.content_type(pid: cocina_obj.externalIdentifier).first
      end
    end

    # returns the name of the project by examining the objects tags
    # @return [String] first project tag value if one exists (blank if none)
    def project_name
      project_tag_id = 'Project : '
      content_tag = AdministrativeTags.for(pid: cocina_obj.externalIdentifier).select { |tag| tag.include?(project_tag_id) }
      content_tag.empty? ? '' : content_tag[0].gsub(project_tag_id, '').strip
    end

    # returns an array of arrays, each element contains an array of [name, value] of DOR object tags in the format expected to pass to Goobi
    # the name of the tag is the first namespace part of the tag (before first colon), value of the tag is everything after this
    # @return [Array] of GoobiTag objects
    def goobi_tag_list
      AdministrativeTags.for(pid: cocina_obj.externalIdentifier).map do |tag|
        tag_split = tag.split(':', 2).map(&:strip) # only split on the first colon
        GoobiTag.new(name: tag_split[0], value: tag_split[1])
      end
    end

    # returns true or false depending if the specially defined goobi DPG ocr tag is present in the object
    # @return [boolean]
    def goobi_ocr_tag_present?
      @goobi_ocr_tag_present ||= begin
        dpg_goobi_ocr_tag = 'DPG : OCR : TRUE'
        AdministrativeTags.for(pid: cocina_obj.externalIdentifier).any? { |tag| tag.casecmp(dpg_goobi_ocr_tag).zero? } # case insensitive compare
      end
    end

    # returns the first collection_id the object is contained in (if any)
    # @return [String] collection druid the item is in (blank if none)
    def collection_id
      @collection_id ||= cocina_obj.structural&.isMemberOf.present? ? cocina_obj.structural.isMemberOf.first : ''
    end

    # returns the name of the first collection the object is contained in (if any)
    # @return [String] first collection name the item is in (blank if none)
    def collection_name
      @collection_name ||= collection_id == '' ? '' : CocinaObjectStore.find(collection_id).label
    end

    def title_or_label
      if cocina_obj.description
        desc_ng_xml = Cocina::ToFedora::Descriptive.transform(cocina_obj.description, cocina_obj.externalIdentifier)
        title_element = ModsUtils.primary_title_info(desc_ng_xml)
        return title_element.content.strip if title_element.respond_to?(:content) && title_element.content.present?
      end

      cocina_obj.label
    end
  end
end
