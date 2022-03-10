# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class ObjectsController < ApplicationController
  before_action :load_cocina_object, only: %i[update_doi_metadata update_marc_record notify_goobi accession destroy show]

  rescue_from(CocinaObjectStore::CocinaObjectNotFoundError) do |e|
    json_api_error(status: :not_found, message: e.message)
  end

  rescue_from(Dry::Struct::Error) do |e|
    json_api_error(status: :internal_server_error, message: e.message)
    raise e
  end

  # No longer be necessary when remove Fedora.
  rescue_from(Cocina::Mapper::UnexpectedBuildError) do |e|
    json_api_error(status: :unprocessable_entity,
                   title: 'Unexpected Cocina::Mapper.build error',
                   message: e.cause,
                   meta: { backtrace: e.cause.backtrace })
  end

  # No longer be necessary when remove Fedora.
  rescue_from(SolrConnectionError) do |e|
    json_api_error(status: :internal_server_error,
                   title: 'Unable to reach Solr',
                   message: e.message)
  end

  def create
    return json_api_error(status: :service_unavailable, message: 'Registration is temporarily disabled') unless Settings.enabled_features.registration

    model_request = Cocina::Models.build_request(params.except(:action, :controller, :assign_doi).to_unsafe_h)
    cocina_object = CocinaObjectStore.create(model_request, assign_doi: params[:assign_doi])

    add_headers(cocina_object)
    render status: :created, location: object_path(cocina_object.externalIdentifier), json: Cocina::Models.without_metadata(cocina_object)
  rescue SymphonyReader::ResponseError => e
    Honeybadger.notify(e)
    json_api_error(status: :bad_gateway, title: 'Catalog connection error', message: 'Unable to read descriptive metadata from the catalog')
  rescue SymphonyReader::NotFound => e
    json_api_error(status: :bad_request, title: 'Catkey not found in Symphony', message: e.message)
  rescue Cocina::RoundtripValidationError => e
    Honeybadger.notify(e)
    json_api_error(status: e.status, message: e.message)
  rescue Cocina::ValidationError => e
    json_api_error(status: e.status, message: e.message)
  end

  def update
    cocina_object = Cocina::Models.build(params.except(:action, :controller, :id).to_unsafe_h)
    # ETag / optimistic locking is optional.
    etag = from_etag(request.headers['If-Match'])
    updated_cocina_object = if etag
                              CocinaObjectStore.save(Cocina::Models.with_metadata(cocina_object, etag))
                            else
                              CocinaObjectStore.save(cocina_object, skip_lock: true)
                            end

    add_headers(updated_cocina_object)
    render json: Cocina::Models.without_metadata(updated_cocina_object)
  # This rescue will no longer be necessary when remove Fedora.
  rescue Cocina::RoundtripValidationError => e
    Honeybadger.notify(e)
    json_api_error(status: e.status, message: e.message)
  rescue Cocina::ValidationError => e
    json_api_error(status: e.status, message: e.message)
  rescue CocinaObjectStore::StaleLockError => e
    json_api_error(status: :precondition_failed,
                   title: 'ETag mismatch',
                   message: "You are attempting to update a stale copy of the object: #{e.message} Refetch the object and attempt your change again.")
  end

  def show
    return head :not_modified if from_etag(request.headers['If-None-Match']) == @cocina_object.lock

    add_headers(@cocina_object)
    render json: Cocina::Models.without_metadata(@cocina_object)
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
    if VersionService.in_accessioning?(@cocina_object)
      return json_api_error(status: :conflict,
                            message: 'This object is already in accessioning, it can not be accessioned again until the workflow is complete')
    end

    updated_cocina_object = @cocina_object
    # if this is an existing versionable object, open and close it without starting accessionWF
    if VersionService.can_open?(@cocina_object, params)
      updated_cocina_object = VersionService.open(@cocina_object, params, event_factory: EventFactory)
      VersionService.close(updated_cocina_object, params.merge(start_accession: false), event_factory: EventFactory)
    # if this is an existing accessioned object that is currently open, just close it without starting accessionWF
    elsif VersionService.open?(@cocina_object)
      VersionService.close(@cocina_object, params.merge(start_accession: false), event_factory: EventFactory)
    end

    # initialize workflow
    workflow_client.create_workflow_by_name(@cocina_object.externalIdentifier, workflow, version: updated_cocina_object.version.to_s)
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
    Dor::UpdateMarcRecordService.new(@cocina_object, thumbnail_service: ThumbnailService.new(@cocina_object)).update
    head :created
  end

  # Called by the robots.
  def update_doi_metadata
    return head :no_content unless Settings.enabled_features.datacite_update && @cocina_object.identification.doi

    # Check to see if these meet the conditions necessary to export to datacite
    unless Cocina::ToDatacite::Attributes.exportable?(@cocina_object)
      return json_api_error(status: :conflict,
                            message: "Item requested a DOI be updated, but it doesn't meet all the preconditions. " \
                                     'Datacite requires that this object have creators and a datacite extension with resourceTypeGeneral')
    end

    # We can remove this line when we upgrade to Rails 6 and just pass cocina_object.
    serialized_item = Cocina::Serializer.new.serialize(@cocina_object)
    UpdateDoiMetadataJob.perform_later(serialized_item)

    head :accepted
  end

  def destroy
    DeleteService.destroy(@cocina_object.externalIdentifier)
    head :no_content
  rescue StandardError => e
    json_api_error(status: :internal_server_error,
                   title: "Internal server error destroying #{@cocina_object.externalIdentifier}",
                   message: e.message)
  end

  # This endpoint is called by the goobi-notify process in the goobiWF
  # (code in https://github.com/sul-dlss/common-accessioning/blob/main/lib/robots/dor_repo/goobi/goobi_notify.rb)
  # This proxies a request to the Goobi server and proxies it's response to the client.
  def notify_goobi
    response = Dor::Goobi.new(@cocina_object).register
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

  def add_headers(cocina_object)
    headers['X-Created-At'] = cocina_object.created.httpdate
    headers['Last-Modified'] = cocina_object.modified.httpdate
    headers['Etag'] = "W/\"#{cocina_object.lock}\""
  end

  def from_etag(etag)
    return nil if etag.nil?

    return etag unless etag.start_with?('W/')

    # Remove leading W/" and trailing "
    # Delete trailing -gzip added by mod_default. See https://github.com/rails/rails/issues/19056
    etag[3..-2].delete_suffix('-gzip')
  end
  # rubocop:enable Metrics/ClassLength
end
