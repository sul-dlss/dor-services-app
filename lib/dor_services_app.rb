require 'dor/workflow_archiver'

module Dor

  class DorServicesApi < Grape::API

    version 'v1', :using => :path

    format :txt
    default_format :txt

    rescue_from :all do |e|
      LyberCore::Log.exception(e)
      rack_response(e.message, 500)
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

      def create_archiver
        arch = Dor::WorkflowArchiver.new
        arch.connect_to_db
        arch
      end

      def archiver
        @archiver ||= create_archiver
      end

    end

    resource :about do
      # Simple ping to see if app is up
      get do
        @version ||= IO.readlines('VERSION').first
        "ok\nversion: #{@version}"
      end
    end

    resource :workflows do

      http_basic do |u,p|
        u == Dor::Config.dor.service_user && p == Dor::Config.dor.service_password
      end

      get '/:wf_name/initial' do
        content_type 'application/xml'
        Dor::WorkflowObject.initial_workflow params[:wf_name]
      end

    end

    resource :objects do

      http_basic do |u,p|
        u == Dor::Config.dor.service_user && p == Dor::Config.dor.service_password
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
            @item = Dor::Item.find(params[:id]) if(params[:ver_num].nil? || params[:ver_num].strip == '')
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

        resource :publish do
          post do
            @item.publish_metadata
          end
        end

        resource :versions do

          post do
            @item.open_new_version
            @item.save
            @item.current_version
          end


          get '/current' do
            @item.current_version
          end

          post '/current/close' do
            request.body.rewind
            body = request.body.read
            if(body.strip.empty?)
              sym_params = nil
            else
              raw_params = JSON.parse body
              sym_params = Hash[raw_params.map{|(k,v)| [k.to_sym,v]}]
              if(sym_params[:significance])
                sym_params[:significance] = sym_params[:significance].to_sym
              end
            end
            @item.close_version sym_params
            "version #{@item.current_version} closed"
          end
        end #

        resource '/workflows/:wf_name/archive' do

          post do
            version = @item.current_version
            archiver.archive_one_datastream 'dor', params[:id], params[:wf_name], version
            "#{params[:wf_name]} version #{version} archived"
          end

          resource ':ver_num' do

             post do
               version = params[:ver_num]
	             archiver.archive_one_datastream 'dor', params[:id], params[:wf_name], version
               "#{params[:wf_name]} version #{version} archived"
             end

          end

        end
      end # :id
    end # :objects



  end #class

end # module
