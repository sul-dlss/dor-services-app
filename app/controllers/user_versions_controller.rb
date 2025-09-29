# frozen_string_literal: true

# Controller for user versions
class UserVersionsController < ApplicationController
  before_action :find_repository_object, except: %i[create]
  before_action :find_user_version, only: %i[show update solr]

  rescue_from UserVersionService::UserVersioningError do |e|
    json_api_error(status: :unprocessable_content, message: e.message)
  end

  def index
    render json: { user_versions: @repository_object.user_versions.map(&:as_json) }
  end

  def show
    render json: @user_version.repository_object_version.to_cocina_with_metadata
  rescue RepositoryObjectVersion::NoCocina
    json_api_error(status: :not_found, message: 'No Cocina for specified version')
  end

  def create
    user_version = UserVersionService.create(druid: druid_param, version: params[:version])
    render json: user_version.as_json, status: :created
  end

  def update
    if params.key?(:withdrawn)
      @user_version = UserVersionService.withdraw(druid: druid_param, user_version: user_version_param,
                                                  withdraw: params[:withdrawn])
    end
    if params.key?(:version)
      @user_version = UserVersionService.move(druid: druid_param, version: params[:version],
                                              user_version: user_version_param)
    end

    render json: @user_version.as_json
  end

  def solr
    render json: Indexing::Builders::DocumentBuilder.for(
      model: @user_version.repository_object_version.to_cocina_with_metadata
    ).to_solr
  end

  private

  def druid_param
    params[:object_id]
  end

  def user_version_param
    params[:id]
  end

  def find_repository_object
    @repository_object = RepositoryObject.find_by!(external_identifier: druid_param)
  end

  def find_user_version
    @user_version = @repository_object.user_versions.find_by!(version: user_version_param)
  end
end
