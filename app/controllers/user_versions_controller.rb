# frozen_string_literal: true

# Controller for user versions
class UserVersionsController < ApplicationController
  before_action :find_repository_object
  before_action :find_user_version, only: %i[show update solr]

  def index
    render json: { user_versions: @repository_object.user_versions.map(&:as_json) }
  end

  def show
    render json: @user_version.repository_object_version.to_cocina_with_metadata
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
    @user_version.withdrawn = params[:withdrawn] if params.key?(:withdrawn)
    if params.key?(:version)
      repository_object_version = @repository_object.versions.find_by!(version: params[:version])
      @user_version.repository_object_version = repository_object_version
    end
    if @user_version.save
      render json: @user_version.as_json
    else
      json_api_error(status: :unprocessable_entity, message: @user_version.errors.full_messages.to_sentence)
    end
  end

  def solr
    render json: Indexing::Builders::DocumentBuilder.for(
      model: @user_version.repository_object_version.to_cocina_with_metadata
    ).to_solr
  end

  private

  def find_repository_object
    @repository_object = RepositoryObject.find_by!(external_identifier: params[:object_id])
  end

  def find_user_version
    @user_version = @repository_object.user_versions.find_by!(version: params[:id])
  end
end
