# frozen_string_literal: true

# Controller for repository object versions.
class VersionsController < ApplicationController
  before_action :load_cocina_object, only: %i[create]
  before_action :check_cocina_object_exists, only: %i[index]
  before_action :load_version, only: %i[current close_current destroy_current status]
  before_action :load_repository_object_version, only: %i[show solr]

  rescue_from RepositoryObjectVersion::NoCocina do |e|
    render build_error('No content for this version', e, status: :bad_request)
  end

  rescue_from(CocinaObjectStore::CocinaObjectNotFoundError) do |e|
    json_api_error(status: :not_found, message: e.message)
  end

  def index
    render json: { versions: repository_object_version_content(find_repository_object.versions) }
  end

  def show
    render json: @repository_object_version.to_cocina_with_metadata
  end

  def create
    updated_cocina_object = VersionService.open(cocina_object: @cocina_object, **create_params)

    add_headers(updated_cocina_object)
    render json: Cocina::Models.without_metadata(updated_cocina_object)
  rescue VersionService::VersioningError => e
    render build_error('Unable to open version', e)
  rescue Preservation::Client::Error => e
    render build_error('Unable to open version due to preservation client error', e, status: :internal_server_error)
  end

  def current
    render plain: @version
  end

  def close_current
    VersionService.close(druid: params[:object_id], version: @version, **close_params)
    render plain: "version #{@version} closed"
  rescue VersionService::VersioningError => e
    render build_error('Unable to close version', e)
  end

  def destroy_current
    # Updating RepositoryObject synchronously, but cleaning up directories and workflows asynchronously.
    VersionService.discard(druid: params[:object_id], version: @version)
    CleanupVersionJob.perform_later(druid: params[:object_id], version: @version)

    head :no_content
  rescue VersionService::VersioningError => e
    render build_error('Unable to delete version', e, status: :conflict)
  end

  def status
    render json: status_for(druid: params[:object_id], version: @version)
  end

  def batch_status
    druids = params.require([:externalIdentifiers]).first
    statuses = druids.filter_map do |druid|
      version = CocinaObjectStore.version(druid)
      [druid, status_for(druid: druid, version: version)]
    rescue CocinaObjectStore::CocinaObjectNotFoundError
      nil
    end
    render json: statuses.to_h
  end

  def solr
    render json: Indexing::Builders::DocumentBuilder.for(
      model: @repository_object_version.to_cocina_with_metadata
    ).to_solr
  end

  private

  # JSON-API error response
  def build_error(msg, err, status: :unprocessable_content)
    {
      json: {
        errors: [
          {
            status: Rack::Utils::SYMBOL_TO_STATUS_CODE[status].to_s,
            title: msg,
            detail: err.message
          }
        ]
      },
      content_type: 'application/vnd.api+json',
      status:
    }
  end

  def create_params
    params.require(:description)
    new_params = params.permit(
      :assume_accessioned,
      :description,
      :opening_user_name
    ).to_h.symbolize_keys
    boolean_param(new_params, :assume_accessioned)
  end

  def close_params
    new_params = params.permit(
      :description,
      :start_accession,
      :user_name,
      :user_versions
    ).to_h.symbolize_keys
    new_params[:user_version_mode] = new_params.delete(:user_versions).to_sym if new_params.key?(:user_versions)
    boolean_param(new_params, :start_accession)
  end

  def boolean_param(params_hash, key)
    params_hash[key] = ActiveModel::Type::Boolean.new.cast(params_hash[key]) if params_hash.key?(key)
    params_hash
  end

  def load_version
    @version = CocinaObjectStore.version(params[:object_id])
  end

  def repository_object_version_content(repository_object_versions)
    repository_object_versions.map do |repository_object_version|
      {
        versionId: repository_object_version.version,
        message: repository_object_version.version_description,
        cocina: repository_object_version.has_cocina?
      }
    end
  end

  def find_repository_object
    RepositoryObject.find_by!(external_identifier: params[:object_id])
  end

  def load_repository_object_version
    @repository_object_version = find_repository_object.versions.find_by!(version: params[:id])
  end

  def status_for(druid:, version:)
    workflow_state_service = WorkflowStateService.new(druid:, version:)
    version_service = VersionService.new(druid:, version:, workflow_state_service:)
    repository_object = RepositoryObject.find_by!(external_identifier: druid)
    version_description = repository_object.versions.select(:version_description).find_by!(version:).version_description

    {
      versionId: version,
      open: version_service.open?,
      openable: version_service.can_open?(check_preservation: false),
      assembling: workflow_state_service.assembling?,
      accessioning: workflow_state_service.accessioning?,
      closeable: version_service.can_close?,
      discardable: version_service.can_discard?,
      versionDescription: version_description
    }
  end
end
