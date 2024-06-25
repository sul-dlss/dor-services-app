# frozen_string_literal: true

# Controller for user versions
class UserVersionsController < ApplicationController
  before_action :find_repository_object

  def index
    render json: { user_versions: @repository_object.user_versions.map(&:as_json) }
  end

  def show
    user_version = @repository_object.user_versions.find_by!(version: params[:id])
    render json: user_version.repository_object_version.to_cocina_with_metadata
  rescue RepositoryObjectVersion::NoCocina
    json_api_error(status: :not_found, message: 'No Cocina for specified version')
  end

  def create
    repository_object_version = @repository_object.versions.find_by!(version: params[:version])
    user_version = UserVersion.new(repository_object_version:)
    if user_version.save
      render json: user_version.as_json, status: :created
    else
      json_api_error(status: :unprocessable_entity, message: user_version.errors.full_messages.to_sentence)
    end
  end

  def update
    user_version = @repository_object.user_versions.find_by!(version: params[:id])
    user_version.withdrawn = params[:withdrawn] if params.key?(:withdrawn)
    if params.key?(:version)
      repository_object_version = @repository_object.versions.find_by!(version: params[:version])
      user_version.repository_object_version = repository_object_version
    end
    if user_version.save
      render json: user_version.as_json
    else
      json_api_error(status: :unprocessable_entity, message: user_version.errors.full_messages.to_sentence)
    end
  end

  private

  def find_repository_object
    @repository_object = RepositoryObject.find_by!(external_identifier: params[:object_id])
  end
end
