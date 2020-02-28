# frozen_string_literal: true

class ObjectsController < ApplicationController
  before_action :load_item, except: [:create]

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  rescue_from(Dor::ParameterError) do |e|
    render status: :bad_request, plain: e.message
  end

  rescue_from(Dor::DuplicateIdError) do |e|
    render status: :conflict, plain: e.message
  end

  rescue_from(Dry::Struct::Error) do |e|
    render status: :internal_server_error, plain: e.message
    raise e
  end

  rescue_from(SymphonyReader::ResponseError) do |e|
    render status: :bad_gateway, plain: e.message
  end

  def create
    return legacy_register if params[:admin_policy] # This is a required parameter for the legacy registration

    cocina_object = Cocina::ObjectCreator.create(params.to_unsafe_h)

    render status: :created, location: object_path(cocina_object.externalIdentifier), json: cocina_object
  end

  # Register new objects in DOR
  def legacy_register
    begin
      reg_response = RegistrationService.create_from_request(create_params, event_factory: EventFactory)
    rescue ArgumentError => e
      return render status: :unprocessable_entity, plain: e.message
    end

    respond_to do |format|
      format.all { render status: :created, location: reg_response.location, plain: reg_response.to_txt }
      format.json { render status: :created, location: reg_response.location, json: reg_response }
    end
  end

  def show
    render json: Cocina::Mapper.build(@item)
  end

  # Initialize specified workflow (assemblyWF by default), and also version if needed
  # called by pre-assembly, goobi and lybservices-scripts to kick off accessioning for a new or existing object
  #
  # You can specify params when POSTing to this method to include when opening a version (if that is required to accession).
  # The optional versioning params are included below for reference.  You can also optionally include a workflow to initialize
  #   (which defaults to assemblyWF)
  # @option opts [String] :significance set significance (major/minor/patch) of version change
  # @option opts [String] :description set description of version change
  # @option opts [String] :opening_user_name add opening username to the events datastream
  # @option opts [String] :workflow the workflow to start (defaults to 'assemblyWF')
  def accession
    workflow = params[:workflow] || default_start_accession_workflow

    # if this is an existing versionable object, open and close it without starting accessioning
    if VersionService.can_open?(@item, params)
      VersionService.open(params)
      VersionService.close(params.merge(start_accession: false))
    end

    # initialize workflow
    workflow_client.create_workflow_by_name(@item.pid, workflow, version: @item.current_version)
    head :created
  end

  # called from Argo, the accessionWF and from the releaseWF.
  # Takes an optional 'workflow' argument, which will call back to
  # the 'publish-complete' step of that workflow if provided
  def publish
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'publish_request_received', data: { background_job_result_id: result.id })

    PublishJob.perform_later(druid: params[:id], background_job_result: result, workflow: params[:workflow])
    head :created, location: result
  end

  def preserve
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'preserve_request_received', data: { background_job_result_id: result.id })

    PreserveJob.perform_later(druid: params[:id], background_job_result: result)
    head :created, location: result
  end

  def update_marc_record
    Dor::UpdateMarcRecordService.new(@item).update
    head :created
  end

  # This endpoint is called by the goobi-notify process in the goobiWF
  # (code in https://github.com/sul-dlss/common-accessioning/blob/master/lib/robots/dor_repo/goobi/goobi_notify.rb)
  # This proxies a request to the Goobi server and proxies it's response to the client.
  def notify_goobi
    response = Dor::Goobi.new(@item).register
    return render status: :conflict, plain: response.body if response.status == 409

    proxy_faraday_response(response)
  end

  private

  def workflow_client
    WorkflowClientFactory.build
  end

  def proxy_faraday_response(response)
    render status: response.status, content_type: response.headers['Content-Type'], body: response.body
  end

  def create_params
    params.except(:action, :controller).to_unsafe_h.merge(body_params)
  end

  def default_start_accession_workflow
    'assemblyWF'
  end

  def body_params
    case request.content_type
    when 'application/xml', 'text/xml'
      Hash.from_xml(request.body.read)
    when 'application/json', 'text/json'
      JSON.parse(request.body.read)
    else
      {}
    end
  end
end
