module Dor
  class Goobi < ServiceItem
    def register
      handler = proc do |exception, attempt_number, _total_delay|
        if attempt_number >= Dor::Config.goobi.max_tries
          throw :error, :message => "#{exception.class} on goobi notification web service call #{attempt_number} for #{@druid_obj.id}", :status => 500
        end
      end

      # rubocop:disable Metrics/LineLength
      with_retries(max_tries: Dor::Config.goobi.max_tries, handler: handler, base_sleep_seconds: Dor::Config.goobi.base_sleep_seconds, max_sleep_seconds: Dor::Config.goobi.max_sleep_seconds) do |_attempt|
        response = RestClient.post(Dor::Config.goobi.url, xml_request, :content_type => 'application/xml') { |resp, _request, _result| resp }
        response
      end
      # rubocop:enable Metrics/LineLength
    end

    def xml_request
      <<-END
        <stanfordCreationRequest>
            <objectId>#{@druid_obj.id}</objectId>
            <objectType>#{object_type}</objectType>
            <sourceID>#{@druid_obj.source_id.encode(:xml => :text)}</sourceID>
            <title>#{@druid_obj.label.encode(:xml => :text)}</title>
            <contentType>#{content_type}</contentType>
            <project>#{project_name.encode(:xml => :text)}</project>
            <catkey>#{ckey}</catkey>
            <barcode>#{barcode}</barcode>
            <collectionId>#{collection_id}</collectionId>
            <collectionName>#{collection_name.encode(:xml => :text)}</collectionName>
            <sdrWorkflow>#{Dor::Config.goobi.dpg_workflow_name}</sdrWorkflow>
            <goobiWorkflow>#{goobi_workflow_name}</goobiWorkflow>
            <ocr>#{goobi_ocr_tag_present?}</ocr>
            <tags>
              #{goobi_tag_list.map { |tag_name, tag_value| "<tag name=\"#{tag_name}\" value=\"#{tag_value}\"></tag>" }.join("\n")}
            </tags>
        </stanfordCreationRequest>
      END
    end
  end
end
