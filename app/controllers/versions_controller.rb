# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_cocina_object, only: %i[create]
  before_action :check_cocina_object_exists, only: %i[index]
  before_action :load_version, only: %i[current close_current openable status]

  def index
    repository_object = RepositoryObject.find_by!(external_identifier: params[:object_id])

    # add an entry with version id and description for each RepositoryObjectVersion

    render json: { versions: repository_object_version_content(repository_object.versions) }
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

  def openable
    render plain: VersionService.can_open?(druid: params[:object_id], version: @version).to_s
  rescue Preservation::Client::Error => e
    render build_error('Unable to check if openable due to preservation client error', e, status: :internal_server_error)
  end

  def status
    version_service = VersionService.new(druid: params[:object_id], version: @version)
    workflow_state_service = WorkflowStateService.new(druid: params[:object_id], version: @version)

    render json: {
      versionId: @version,
      open: version_service.open?,
      openable: version_service.can_open?,
      assembling: workflow_state_service.assembling?,
      accessioning: workflow_state_service.accessioning?,
      closeable: version_service.can_close?
    }
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
        message: repository_object_version.version_description
      }
    end
  end
end
