# frozen_string_literal: true

# Controller for user versions
class UserVersionsController < ApplicationController
  def index
    repository_object = RepositoryObject.find_by!(external_identifier: params[:object_id])

    render json: { user_versions: repository_object.user_versions.map(&:as_json) }
  end

  def show
    repository_object = RepositoryObject.find_by!(external_identifier: params[:object_id])
    user_version = repository_object.user_versions.find_by!(version: params[:id])
    render json: user_version.repository_object_version.to_cocina_with_metadata
  rescue RepositoryObjectVersion::NoCocina
    json_api_error(status: :not_found, message: 'No Cocina for specified version')
  end
end
