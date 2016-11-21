class ObjectsController < ApplicationController
  before_action :load_item, except: [:create]

  rescue_from(Dor::ParameterError) do |e|
    render status: 400, plain: e.message
  end

  rescue_from(Dor::DuplicateIdError) do |e|
    render status: 409, plain: e.message, location: object_location(e.pid)
  end
  
  rescue_from(DruidTools::SameContentExistsError, DruidTools::DifferentContentExistsError) do |e|
    render status: 409, plain: e.message
  end
  
  # Register new objects in DOR
  def create
    Rails.logger.info(params.inspect)
    reg_response = Dor::RegistrationService.create_from_request(create_params)
    Rails.logger.info(reg_response)
    pid = reg_response['pid']
    
    respond_to do |format|
      format.json { render status: 201, location: object_location(pid), json: Dor::RegistrationResponse.new(reg_response) }
      format.txt { render status: 201, location: object_location(pid), plain: Dor::RegistrationResponse.new(reg_response).to_txt }
    end
  end     
  
  # The param, source, can be passed as apended parameter to url:
  #  http://lyberservices-dev/dor/v1/objects/{druid}/initialize_workspace?source=/path/to/content/dir/for/druid
  # or
  # It can be passed in the body of the request as application/x-www-form-urlencoded parameters, as if submitted from a form
  # TODO: We could get away with loading a simple object that mixes in Dor::Assembleable.  It just needs to implement #pid
  def initialize_workspace
    @item.initialize_workspace(params[:source])
    head :created
  end
  
  def publish
    @item.publish_metadata
    head :created
  end

  def update_marc_record
    Dor::UpdateMarcRecordService.new(@item).update
    head :created
  end

  def notify_goobi
    response = Dor::Goobi.new(@item).register
    proxy_rest_client_response(response)
  end
  
  # You can post a release tag as JSON in the body to add a release tag to an item.
  # If successful it will return a 201 code, otherwise the error that occurred will bubble to the top
  #
  # 201
  def release_tags
    request.body.rewind
    body = request.body.read
    raw_params = JSON.parse body # This should produce a hash in valid release tag form=
    raw_params.symbolize_keys!

    if raw_params.key?(:release) && (raw_params[:release] == true || raw_params[:release] == false)
      @item.add_release_node(raw_params[:release], raw_params)
      @item.save
      head :created
    else
      render status: 400, plain: "A release attribute is required in the JSON, and its value must be either 'true' or 'false'. You sent '#{raw_params[:release]}'"
    end
  end

  # Initiate a workflow by name
  def apo_workflows
    workflow = if params[:wf_name].ends_with? 'WF'
                 params[:wf_name]
               else
                 "#{params[:wf_name]}WF"
               end

    @item.initiate_apo_workflow(workflow)
    
    head :created
  end

  
  private

  def fedora_base
    URI.parse(Dor::Config.fedora.safeurl.sub(/\/*$/, '/'))
  end

  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end
  
  def create_params
    params.to_unsafe_h.merge(body_params)
  end

  def body_params
    return {} unless request.body.any?

    case request.content_type
    when 'application/xml', 'text/xml'
      Hash.from_xml(request.body.read)
    when 'application/json', 'text/json'
      JSON.parse(request.body.read)
    end
  end
end
