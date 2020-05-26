# frozen_string_literal: true

# Administrative tags controller (nested resource under objects)
class AdministrativeTagsController < ApplicationController
  # This just validates that this is an existing object
  before_action :load_item, only: %i[create index update destroy]

  rescue_from(ActiveFedora::ObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  # Show administrative tags for an object
  def index
    render json: AdministrativeTags.for(pid: params[:object_id])
  end

  def search
    results = TagLabel.where('tag like ?', "#{params[:q]}%").limit(10).pluck(:tag)
    render json: results
  end

  def create
    AdministrativeTags.create(pid: params[:object_id],
                              tags: params.require(:administrative_tags),
                              replace: params[:replace])
  rescue ActiveRecord::RecordInvalid => e
    Honeybadger.notify('[SURPRISE] AdministrativeTags.create raised AR::RecordInvalid!',
                       context: {
                         druid: params[:object_id],
                         tags: params.require(:administrative_tags),
                         replace: params[:replace]
                       })
    render status: :conflict, plain: e.message
  else
    head :created
  end

  def update
    AdministrativeTags.update(pid: params[:object_id],
                              current: CGI.unescape(params[:id]),
                              new: params.require(:administrative_tag))
  rescue ActiveRecord::RecordNotFound => e
    render status: :not_found, plain: e.message
  rescue ActiveRecord::RecordInvalid => e
    Honeybadger.notify('[SURPRISE] AdministrativeTags.update raised AR::RecordInvalid!',
                       context: {
                         druid: params[:object_id],
                         current: CGI.unescape(params[:id]),
                         new: params.require(:administrative_tag)
                       })
    render status: :conflict, plain: e.message
  else
    head :no_content
  end

  def destroy
    AdministrativeTags.destroy(pid: params[:object_id], tag: CGI.unescape(params[:id]))
  rescue ActiveRecord::RecordNotFound => e
    render status: :not_found, plain: e.message
  else
    head :no_content
  end
end
