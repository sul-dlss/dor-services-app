module Dor

  class DorServicesApi < Grape::API

    version 'v1', :using => :header
    
    format :txt
    default_format :txt

    rescue_from :all do |e|
      LyberCore::Log.exception(e)
      rack_response(e.message, 500)
    end
    
    http_basic do |u,p|
      u == Dor::Config.dor.service_user && p == Dor::Config.dor.service_password
    end

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
          merge_params(Hash.from_xml(request.body.read))
        when 'application/json','text/json'
          merge_params(JSON.parse(request.body.read))
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
        "ok\n"
      end

      # Register new objects in DOR
      post do
        munge_parameters
        begin
          LyberCore::Log.info(params.inspect)

          dor_obj = Dor::RegistrationService.create_from_request(params)
          pid = dor_obj.pid

          header 'location', object_location(pid)
          status 201
          Dor::RegistrationResponse.new(dor_params.dup.merge({ :location => object_location(pid), :pid => pid }))
        rescue Dor::ParameterError => e
          LyberCore::Log.exception(e)
          error!(e.message, 400)
        rescue Dor::DuplicateIdError => e
          LyberCore::Log.exception(e)
          header 'location', object_location(e.pid)
          error!(e.message, 409)
        end
      end

      resource ':id' do

        helpers do
          def load_item
            @item = Dor::Item.find(params[:id])
          end
        end
        
        before { load_item }

        # The param, source, can be passed as apended parameter to url:
        #  http://lyberservices-dev/dor/v1/objects/{druid}/initialize_workspace?source=/path/to/content/dir/for/druid
        # or
        # It can be passed in the body of the request as application/x-www-form-urlencoded parameters, as if submitted from a form
        # TODO: We could get away with loading a simple object that mixes in Dor::Assembleable.  It just needs to implement #pid
        post :initialize_workspace do
          begin
            @item.initialize_workspace(params[:source])
          rescue DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError => e
            error!(e.message, 409)
          end
        end
        
        resource '/apo_workflows/:wf_name' do

          # Start accessioning
          post do
            workflow = (params[:wf_name] =~ /WF$/ ? params[:wf_name] : params[:wf_name] << 'WF')
            @item.initiate_apo_workflow(workflow)
          end
        
        end # apo_workflows
        
        resource :versions do
          
          post do
            @item.open_new_version
            @item.current_version
          end
          
          
          get '/current' do
            @item.current_version
          end
        end #
        
      end # :id
    end # :objects 

  end #class
  
end # module
