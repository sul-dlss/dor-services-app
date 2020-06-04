# frozen_string_literal: true

class ObjectsController < ApplicationController
  before_action :load_item, except: [:create]

  rescue_from(Cocina::ObjectUpdater::NotImplemented) do |e|
    json_api_error(status: :unprocessable_entity, message: e.message)
  end

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    json_api_error(status: :not_found, message: e.message)
  end

  rescue_from(Dor::ParameterError) do |e|
    json_api_error(status: :bad_request, message: e.message)
  end

  rescue_from(Dor::DuplicateIdError) do |e|
    json_api_error(status: :conflict, message: e.message)
  end

  rescue_from(Dry::Struct::Error) do |e|
    json_api_error(status: :internal_server_error, message: e.message)
    raise e
  end

  def create
    cocina_object = Cocina::ObjectCreator.create(params.except(:action, :controller).to_unsafe_h)

    render status: :created, location: object_path(cocina_object.externalIdentifier), json: cocina_object
  rescue SymphonyReader::ResponseError
    json_api_error(status: :bad_gateway, title: 'Catalog connection error', message: 'Unable to read descriptive metadata from the catalog')
  end

  def update
    obj = Dor.find(params[:id])
    cocina_object = Cocina::ObjectUpdater.run(obj, params.except(:action, :controller, :id).to_unsafe_h)

    render json: cocina_object
  end

  def show
    # Etds are not mapping to Etd by default (see adapt_to_cmodel in Dor::Abstract)
    # This hack overrides that behavior and ensures Etds can be mapped to Cocina.
    models = ActiveFedora::ContentModel.models_asserted_by(@item)
    @item = @item.adapt_to(Etd) if models.include?('info:fedora/afmodel:Etd')
    render json: Cocina::Mapper.build(@item)
  rescue Cocina::Mapper::MissingTitle
    json_api_error(status: :unprocessable_entity,
                   title: 'Missing title',
                   message: "All objects are required to have a title, but #{params[:id]} appears to be malformed as a title cannot be found.")
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
      VersionService.open(@item, params, event_factory: EventFactory)
      VersionService.close(@item, params.merge(start_accession: false), event_factory: EventFactory)
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
    queue = params['lane-id'] == 'low' ? :low : :default

    PublishJob.set(queue: queue).perform_later(druid: params[:id], background_job_result: result, workflow: params[:workflow])
    head :created, location: result
  end

  def preserve
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'preserve_request_received', data: { background_job_result_id: result.id })
    queue = params['lane-id'] == 'low' ? :low : :default

    PreserveJob.set(queue: queue).perform_later(druid: params[:id], background_job_result: result)
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
    return json_api_error(status: :conflict, message: response.body) if response.status == 409

    proxy_faraday_response(response)
  end

  private

  def json_api_error(status:, title: nil, message:)
    status_code = Rack::Utils.status_code(status)
    render status: status,
           content_type: 'application/vnd.api+json',
           json: {
             errors: [
               {
                 'status': status_code.to_s,
                 'title': title || Rack::Utils::HTTP_STATUS_CODES[status_code],
                 'detail': message
               }
             ]
           }
  end

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
