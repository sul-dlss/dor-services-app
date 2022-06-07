# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_cocina_object

  def index
    object_versions = ObjectVersion.where(druid: @cocina_object.externalIdentifier)

    return render json: {} if object_versions.empty?

    # add an entry with version id, tag and description for each version
    versions = object_versions.map do |object_version|
      {
        versionId: object_version.version,
        tag: object_version.tag,
        message: object_version.description
      }
    end

    render json: { versions: }
  end

  def create
    updated_cocina_object = VersionService.open(@cocina_object, **create_params)

    add_headers(updated_cocina_object)
    render json: Cocina::Models.without_metadata(updated_cocina_object)
  rescue VersionService::VersioningError => e
    render build_error('Unable to open version', e)
  rescue Preservation::Client::Error => e
    render build_error('Unable to open version due to preservation client error', e, status: :internal_server_error)
  end

  def current
    render plain: @cocina_object.version
  end

  def close_current
    VersionService.close(@cocina_object, **close_params)
    render plain: "version #{@cocina_object.version} closed"
  rescue VersionService::VersioningError => e
    render build_error('Unable to close version', e)
  end

  def openable
    render plain: VersionService.can_open?(@cocina_object).to_s
  rescue Preservation::Client::Error => e
    render build_error('Unable to check if openable due to preservation client error', e, status: :internal_server_error)
  end

  private

  # JSON-API error response
  def build_error(msg, err, status: :unprocessable_entity)
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
    params.require(:significance)
    new_params = params.permit(
      :assume_accessioned,
      :description,
      :opening_user_name,
      :significance
    ).to_h.symbolize_keys
    boolean_param(new_params, :assume_accessioned)
  end

  def close_params
    new_params = params.permit(
      :description,
      :significance,
      :start_accession,
      :user_name
    ).to_h.symbolize_keys
    boolean_param(new_params, :start_accession)
  end

  def boolean_param(params_hash, key)
    params_hash[key] = ActiveModel::Type::Boolean.new.cast(params_hash[key]) if params_hash.key?(key)
    params_hash
  end
end
