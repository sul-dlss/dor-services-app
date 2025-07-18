# frozen_string_literal: true

# Controller for repository objects.
class ObjectsController < ApplicationController
  before_action :load_cocina_object, only: %i[accession destroy show reindex]
  before_action :check_cocina_object_exists, only: :publish

  rescue_from(CocinaObjectStore::CocinaObjectNotFoundError) do |e|
    json_api_error(status: :not_found, message: e.message)
  end

  def show
    return head :not_modified if from_etag(request.headers['If-None-Match']) == @cocina_object.lock

    add_headers(@cocina_object)
    render json: Cocina::Models.without_metadata(@cocina_object)
  end

  def create # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    unless Settings.enabled_features.registration
      return json_api_error(status: :service_unavailable,
                            message: 'Registration is temporarily disabled')
    end

    model_request = Cocina::Models.build_request(params.except(:action, :controller, :assign_doi,
                                                               :user_name).to_unsafe_h)
    cocina_object = CreateObjectService.create(model_request, assign_doi: params[:assign_doi], who: params[:user_name])

    add_headers(cocina_object)
    render status: :created, location: object_path(cocina_object.externalIdentifier),
           json: Cocina::Models.without_metadata(cocina_object)
  rescue Catalog::MarcService::CatalogResponseError => e
    Honeybadger.notify(e)
    json_api_error(status: :bad_gateway, title: 'Catalog connection error',
                   message: 'Unable to read descriptive metadata from the catalog')
  rescue Catalog::MarcService::CatalogRecordNotFoundError => e
    json_api_error(status: :bad_request, title: 'Record not found in catalog', message: e.message)
  rescue Catalog::MarcService::MarcServiceError => e
    Honeybadger.notify(e)
    json_api_error(status: :internal_server_error, message: e.message)
  rescue Cocina::ValidationError => e
    json_api_error(status: e.status, message: e.message)
  rescue Cocina::Models::ValidationError => e
    json_api_error(status: 400, message: e.message)
  end

  def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    cocina_object = Cocina::Models.build(params.except(:action, :controller, :id, :event_description,
                                                       :user_name).to_unsafe_h)
    description = params[:event_description]
    who = params[:user_name]

    # Ensure the id in the path matches the id in the post body.
    if params[:id] != cocina_object.externalIdentifier
      raise Cocina::ValidationError,
            "Identifier on the query and in the body don't match"
    end

    # ETag / optimistic locking is optional.
    etag = from_etag(request.headers['If-Match'])
    updated_cocina_object = if etag
                              UpdateObjectService.update(
                                cocina_object: Cocina::Models.with_metadata(cocina_object, etag), description:, who:
                              )
                            else
                              UpdateObjectService.update(cocina_object:, skip_lock: true, description:, who:)
                            end

    add_headers(updated_cocina_object)
    render json: Cocina::Models.without_metadata(updated_cocina_object)
  rescue Cocina::ValidationError => e
    json_api_error(status: e.status, message: e.message)
  rescue CocinaObjectStore::StaleLockError => e
    json_api_error(status: :precondition_failed,
                   title: 'ETag mismatch',
                   message: "You are attempting to update a stale copy of the object: #{e.message} " \
                            'Refetch the object and attempt your change again.')
  end

  def find
    cocina_object = CocinaObjectStore.find_by_source_id(params[:sourceId])

    add_headers(cocina_object)
    render json: Cocina::Models.without_metadata(cocina_object)
  end

  # Initialize specified workflow (assemblyWF by default), and also version if needed
  # called by pre-assembly and goobi kick off accessioning for a new or existing object
  #
  # You can specify params when POSTing to this method to include when opening a version (if that is required
  # to accession).
  # The versioning params are included below for reference.
  #  :descriptions [String] (required) description of version change
  #  :opening_user_name [String] (optional) opening sunetid to add to the events datastream
  # You can also pass information that will be used to start the workflow:
  #  :workflow [String] (optional) the workflow to start (defaults to 'assemblyWF')
  #  :context [Hash] (optional) workflow context to pass to the workflow service (defaults to nil)
  def accession # rubocop:disable Metrics/AbcSize
    workflow = params[:workflow] || 'assemblyWF'
    EventFactory.create(druid: params[:id], event_type: 'accession_request', data: { workflow: })

    version_service = VersionService.new(druid: @cocina_object.externalIdentifier, version: @cocina_object.version)

    updated_cocina_object = @cocina_object
    unless version_service.open?
      unless version_service.can_open?
        EventFactory.create(druid: params[:id], event_type: 'accession_request_aborted', data: { workflow: })
        return json_api_error(status: :conflict,
                              message: 'This object cannot be opened for versioning.')
      end

      updated_cocina_object = version_service.open(cocina_object: @cocina_object, assume_accessioned: false,
                                                   **version_open_params)
    end

    # initialize workflow
    WorkflowService.create(druid: @cocina_object.externalIdentifier, workflow_name: workflow,
                           version: updated_cocina_object.version.to_s, context: workflow_context)
    head :created
  end

  # Called from Argo.
  def publish
    result = BackgroundJobResult.create
    EventFactory.create(druid: params[:id], event_type: 'publish_request_received',
                        data: { background_job_result_id: result.id })
    PublishJob.set(queue: publish_queue).perform_later(druid: params[:id], background_job_result: result)
    head :created, location: result
  end

  def destroy
    DeleteService.destroy(@cocina_object, user_name: params[:user_name])
    head :no_content
  rescue StandardError => e
    json_api_error(status: :internal_server_error,
                   title: "Internal server error destroying #{@cocina_object.externalIdentifier}",
                   message: e.message)
  end

  def reindex
    Indexer.reindex(cocina_object: @cocina_object)
    head :no_content
  end

  private

  def queue
    params['lane-id'] == 'low' ? :low : :default
  end

  def publish_queue
    params['lane-id'] == 'low' ? :publish_low : :publish_default
  end

  def from_etag(etag)
    return nil if etag.nil?

    return etag unless etag.start_with?('W/')

    # Remove leading W/" and trailing "
    # Delete trailing -gzip added by mod_default. See https://github.com/rails/rails/issues/19056
    etag[3..-2].delete_suffix('-gzip')
  end

  def version_open_params
    params.permit(:description, :opening_user_name).to_h.symbolize_keys
  end

  # workflow context is optionally set in the body of the request as json, with the key 'context'
  def workflow_context
    params.permit(context: {}).to_h[:context]
  end

  def version_close_params
    new_params = params.permit(:description).to_h.symbolize_keys
    new_params[:user_name] = params[:opening_user_name] if params[:opening_user_name]
    new_params
  end
end
