# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ObjectsController < ApplicationController
  before_action :load_item, except: [:create]

  rescue_from(Cocina::ObjectUpdater::NotImplemented) do |e|
    json_api_error(status: :unprocessable_entity, message: e.message)
  end

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    json_api_error(status: :not_found, message: e.message)
  end

  rescue_from(Dry::Struct::Error) do |e|
    json_api_error(status: :internal_server_error, message: e.message)
    raise e
  end

  def create
    return json_api_error(status: :service_unavailable, message: 'Registration is temporarily disabled') unless Settings.enabled_features.registration

    model_request = Cocina::Models.build_request(params.except(:action, :controller).to_unsafe_h)
    cocina_object = Cocina::ObjectCreator.create(model_request)

    # Broadcast this to a topic
    Notifications::ObjectCreated.publish(model: cocina_object) if Settings.rabbitmq.enabled

    render status: :created, location: object_path(cocina_object.externalIdentifier), json: cocina_object
  rescue SymphonyReader::ResponseError
    json_api_error(status: :bad_gateway, title: 'Catalog connection error', message: 'Unable to read descriptive metadata from the catalog')
  rescue Cocina::RoundtripValidationError => e
    Honeybadger.notify(e)
    json_api_error(status: e.status, message: e.message)
  rescue Cocina::ValidationError => e
    json_api_error(status: e.status, message: e.message)
  end

  def update
    fedora_object = Dor.find(params[:id])
    update_request = Cocina::Models.build(params.except(:action, :controller, :id).to_unsafe_h)
    persisted_cocina_object = Cocina::ObjectUpdater.run(fedora_object, update_request)

    # Broadcast this update action to a topic
    Notifications::ObjectUpdated.publish(model: persisted_cocina_object) if Settings.rabbitmq.enabled

    render json: persisted_cocina_object
  rescue Cocina::RoundtripValidationError => e
    Honeybadger.notify(e)
    json_api_error(status: e.status, message: e.message)
  rescue Cocina::ValidationError => e
    json_api_error(status: e.status, message: e.message)
  end

  def show
    # Etds are not mapping to Etd by default (see adapt_to_cmodel in Dor::Abstract)
    # This hack overrides that behavior and ensures Etds can be mapped to Cocina.
    models = ActiveFedora::ContentModel.models_asserted_by(@item)
    @item = @item.adapt_to(Etd) if models.include?('info:fedora/afmodel:Etd')
    headers['Last-Modified'] = @item.modified_date.to_datetime.httpdate
    render json: Cocina::Mapper.build(@item)
  rescue SolrConnectionError => e
    json_api_error(status: :internal_server_error,
                   title: 'Unable to reach Solr',
                   message: e.message)
  rescue Cocina::Mapper::UnexpectedBuildError => e
    json_api_error(status: :unprocessable_entity,
                   title: 'Unexpected Cocina::Mapper.build error',
                   message: e.cause,
                   meta: { backtrace: e.cause.backtrace })
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

    # if this object is currently already in accessioning, we cannot start it again
    if VersionService.in_accessioning?(@item)
      head :not_acceptable
      return
    end

    # if this is an existing versionable object, open and close it without starting accessionWF
    if VersionService.can_open?(@item, params)
      VersionService.open(@item, params, event_factory: EventFactory)
      VersionService.close(@item, params.merge(start_accession: false), event_factory: EventFactory)
    # if this is an existing accessioned object that is currently open, just close it without starting accessionWF
    elsif VersionService.open?(@item)
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

  def unpublish
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'unpublish_request_received', data: { background_job_result_id: result.id })
    queue = params['lane-id'] == 'low' ? :low : :default
    UnpublishJob.set(queue: queue).perform_later(druid: params[:id], background_job_result: result)
    head :accepted, location: result
  end

  def update_marc_record
    Dor::UpdateMarcRecordService.new(@item).update
    head :created
  end

  def destroy
    DeleteService.destroy(@item.pid)
    head :no_content
  rescue StandardError => e
    json_api_error(status: :internal_server_error,
                   title: "Internal server error destroying #{@item.pid}",
                   message: e.message)
  end

  # This endpoint is called by the goobi-notify process in the goobiWF
  # (code in https://github.com/sul-dlss/common-accessioning/blob/main/lib/robots/dor_repo/goobi/goobi_notify.rb)
  # This proxies a request to the Goobi server and proxies it's response to the client.
  def notify_goobi
    response = Dor::Goobi.new(@item).register
    return json_api_error(status: :conflict, message: response.body) if response.status == 409

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
  # rubocop:enable Metrics/ClassLength
end
