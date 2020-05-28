# frozen_string_literal: true

module Dor
  # This class passes data to the Goobi server using a custom XML message that was developed by Intranda
  class Goobi < ServiceItem
    SERVER_ERROR_STATUSES = (500...600).freeze
    class ServerError < StandardError; end

    # Any status that is a 500 or greater and timeouts
    RETRIABLE_EXCEPTIONS = [ServerError,
                            Errno::ETIMEDOUT,
                            Faraday::TimeoutError,
                            Faraday::RetriableResponse].freeze

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

    # We send all tags to Goobi, but "DPG : Workflow : xxx" is the one tag that Goobi uses
    def goobi_xml_tags
      goobi_tag_list.map(&:to_xml).join
    end

    def xml_request
      <<-END
        <stanfordCreationRequest>
            <objectId>#{@druid_obj.id}</objectId>
            <objectType>#{object_type}</objectType>
            <sourceID>#{@druid_obj.source_id.encode(xml: :text)}</sourceID>
            <title>#{title_or_label.encode(xml: :text)}</title>
            <contentType>#{content_type}</contentType>
            <project>#{project_name.encode(xml: :text)}</project>
            <catkey>#{ckey}</catkey>
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
  end
end
