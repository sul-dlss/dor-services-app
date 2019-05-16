# frozen_string_literal: true

module Dor
  # This class passes data to the Goobi server using a custom XML message that was developed by Intranda
  class Goobi < ServiceItem
    # Any RestClient exception that is a 500 or greater
    RETRIABLE_EXCEPTIONS = RestClient::Exceptions::EXCEPTIONS_MAP.select { |k, _v| k >= 500 }.values +
                           [RestClient::RequestTimeout,
                            RestClient::ServerBrokeConnection,
                            RestClient::SSLCertificateNotVerified]

    def register
      with_retries(max_tries: Dor::Config.goobi.max_tries,
                   base_sleep_seconds: Dor::Config.goobi.base_sleep_seconds,
                   max_sleep_seconds: Dor::Config.goobi.max_sleep_seconds,
                   rescue: RETRIABLE_EXCEPTIONS) do |_attempt|
        RestClient.post(Dor::Config.goobi.url, xml_request, content_type: 'application/xml')
      end
    end

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
            <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
            <goobiWorkflow>#{goobi_workflow_name}</goobiWorkflow>
            <ocr>#{goobi_ocr_tag_present?}</ocr>
            <tags>#{goobi_xml_tags}</tags>
        </stanfordCreationRequest>
      END
    end
  end
end
