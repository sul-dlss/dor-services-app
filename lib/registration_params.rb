module Dor
  
  class RegistrationParams
    
    def self.ids_to_hash(ids)
      if ids.nil?
        nil
      else
        Hash[Array(ids).collect { |id| id.split(/:/) }]
      end
    end
    
    # From Argo:
    #             dor_params = {
    #               :pid                => params[:pid],
    #               :admin_policy       => params[:admin_policy],
    #               :content_model      => params[:model],  XXX
    #               :label              => params[:label],
    #               :object_type        => params[:object_type],
    #               :other_ids          => help.ids_to_hash(other_ids),
    #               :parent             => params[:parent],
    #               :source_id          => help.ids_to_hash(params[:source_id]),
    #               :tags               => params[:tag],    XXXXX
    #               :seed_datastream    => params[:seed_datastream],
    #               :initiate_workflow  => Array(params[:initiate_workflow]) + Array(params[:workflow_id])
    #             }
    
=begin
    From RegistrationService spec
    params = {
      :object_type => 'item', 
      :content_model => 'googleScannedBook', 
      :admin_policy => 'druid:kw422qz8181', 
      :label => 'Google : Scanned Book 12345', 
      :agreement_id => 'druid:xf765cv5573', 
      :source_id => { :revs => 'revs123' }, 
      :other_ids => { :catkey => '000', :uuid => '111' }, 
      :tags => ['Google : Google Tag!','Google : Other Google Tag!']
    }
    
    From REVS
    p = {
      :admin_policy=>"druid:qv648vd4392", 
      :source_id=>{"REVS"=>"reg-app-1"},
      :object_type=>"item",
      :tags=>["Project : REVS"],
      :label=>"Avus 1937"
    }
=end
    
    def self.normalize(params)
      other_ids = Array(params[:other_id]).collect do |id|
        if id =~ /^symphony:(.+)$/
          "#{$1.length < 14 ? 'catkey' : 'barcode'}:#{$1}"
        else
          id
        end
      end
      
      if params[:label] == ':auto'
        params.delete(:label)
        params.delete('label')
        metadata_id = Dor::MetadataService.resolvable(other_ids).first
        params[:label] = Dor::MetadataService.label_for(metadata_id)
      end
    
      dor_params = {
        :pid                => params[:pid],
        :admin_policy       => params[:admin_policy],
        :content_model      => params[:model],          # Different symbol
        :label              => params[:label],
        :object_type        => params[:object_type],
        :other_ids          => ids_to_hash(other_ids),
        :parent             => params[:parent],
        :source_id          => ids_to_hash(params[:source_id]),
        :tags               => params[:tag],            # Different symbol
        :seed_datastream    => params[:seed_datastream],
        :initiate_workflow  => Array(params[:initiate_workflow]) + Array(params[:workflow_id])
      }
    end
  end
  
end