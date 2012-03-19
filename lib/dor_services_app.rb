
module Dor
    
  class DorServicesApi < Grape::API
      
    version 'v1'
    
    default_format :txt
    
    Grape::Middleware::Formatter::FORMATTERS[:xml] = Proc.new { |object| object.to_xml }
    
    #rescue_from Dor::ParameterError, :default_status => 400, :backtrace => true
    
    helpers do
      def merge_params(hash)
        # convert camelCase parameter names to under_score, and string keys to symbols
        # e.g., 'objectType' to :object_type
        hash.each_pair { |k,v| 
          key = k.underscore
          params[key.to_sym] = v
        }
      end
      
      def munge_parameters
        case request.content_type
        when 'application/xml','text/xml'
          help.merge_params(Hash.from_xml(request.body.read))
        when 'application/json','text/json'
          help.merge_params(JSON.parse(request.body.read))
        end
      end
            
      def fedora_base
        URI.parse(Dor::Config.fedora.safeurl.sub(/\/*$/,'/'))
      end

      def object_location(pid)
        fedora_base.merge("objects/#{pid}").to_s
      end
      
    end

    resource :objects do
      
      # Simple ping to see if app is up
      get do
        "ok"
      end

      post do
        begin
          dor_params = Dor::RegistrationParams.normalize(params)
          LyberCore::Log.info(dor_params.inspect)
          
          dor_obj = Dor::RegistrationService.register_object(dor_params)
          pid = dor_obj.pid
          
          header 'location', object_location(pid)
          status 201
          Dor::RegistrationResponse.new(dor_params.dup.merge({ :location => object_location(pid), :pid => pid }))
        rescue Dor::ParameterError => e
          error!(e.message, 400)
        rescue Dor::DuplicateIdError => e
          error!(e.message, 409) # TODO figure out how to set headers on error :location => help.object_location(e.pid)
        rescue Exception => e
          error!(e.message, 500)
        end                
      end
              
      resource ':id' do
        
        helpers do
          def load_item
            @item = Dor::Item.load_instance(params[:id])
          end
        end
      
        # The param, source, can be passed as apended parameter to url:
        #  http://lyberservices-dev/v1/dor/objects/{druid}/initialize_workspace?source=/path/to/content/dir
        # or
        # It can be passed in the body of the request as application/x-www-form-urlencoded parameters, as if submitted from a form
        # TODO: We could get away with loading a simple object that mixes in Dor::Assembleable.  It just needs to implement #pid
        post :initialize_workspace do
          begin
            load_item
            @item.initialize_workspace(params[:source])
          rescue Dor::SameContentExistsError, Dor::DifferentContentExistsError => e
            error!(e.message, 409)
          end
        end
      
        post :accession do
          load_item
          @item.initiate_apo_workflow('accessionWF')
        end
      end # :id
    end # :objects 
    
  end #class
  
end # module