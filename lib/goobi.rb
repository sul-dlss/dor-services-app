module Dor
  class Goobi < ServiceItem
    
    def register
      handler = proc do |exception, attempt_number, _total_delay|
        error!("#{exception.class} on goobi notification web service call #{attempt_number} for #{@druid_obj.id}", 500) if attempt_number >= Dor::Config.goobi.max_tries
      end

      with_retries(max_tries: Dor::Config.goobi.max_tries, handler: handler, base_sleep_seconds: Dor::Config.goobi.base_sleep_seconds, max_sleep_seconds: Dor::Config.goobi.max_sleep_seconds) do |_attempt|
        
        url = "#{Dor::Config.goobi.url}"
        response = RestClient.post url, xml_request, :content_type => :xml, :accept=>:xml
        response.code  
      end    
    end
    
    def xml_request
      <<-END
        <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
        <creationRequest>
        <objectId>#{@druid_obj.id}</objectId>
           <objectType>#{object_type}</objectType>
            <sourceID>#{@druid_obj.source_id.encode(:xml => :text)}</sourceID>
            <title>#{@druid_obj.label.encode(:xml => :text)}</title>
            <contentType>#{@druid_obj.content_type_tag}</contentType>
            <project>#{project_name.encode(:xml => :text)}</project>
            <catkey>#{ckey}</catkey>
            <barcode>#{barcode}</barcode>
            <collectionId>#{collection_id}</collecitonId>
            <collectionName>#{collection_name.encode(:xml => :text)}</collectionName>
            <sdrWorkflow>dpgImageWF</sdrWorkflow>
            <goobiWorkflow>name</goobiWorkflow>
        </creationRequest>  
      END
    end
    
  end
end