# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_cocina_object

  def index
    # This can be removed after migration.
    VersionMigrationService.find_and_migrate(@cocina_object.externalIdentifier)

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

    render json: { versions: versions }
  end

  def create
    updated_cocina_object = VersionService.open(@cocina_object, **create_params, event_factory: EventFactory)

    add_headers(updated_cocina_object)
    render json: Cocina::Models.without_metadata(updated_cocina_object)
  rescue Dor::Exception => e
    render build_error('Unable to open version', e)
  rescue Preservation::Client::Error => e
    render build_error('Unable to open version due to preservation client error', e, status: :internal_server_error)
  end

  def current
    render plain: @cocina_object.version
  end

  def close_current
    VersionService.close(@cocina_object, **close_params, event_factory: EventFactory)
    render plain: "version #{@cocina_object.version} closed"
  rescue Dor::Exception => e
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
      status: status
    }
  end

  def create_params
    params.require(:description)
    params.require(:significance)
    params.permit(
      :assume_accessioned,
      :description,
      :opening_user_name,
      :significance
    ).to_h.symbolize_keys
  end

  def close_params
    params.permit(
      :description,
      :significance,
      :start_accession,
      :user_name
    ).to_h.symbolize_keys
  end
end
