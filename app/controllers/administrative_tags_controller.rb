# frozen_string_literal: true

# Administrative tags controller (nested resource under objects)
class AdministrativeTagsController < ApplicationController
  before_action :load_cocina_object, only: %i[create update destroy]

  rescue_from(CocinaObjectStore::CocinaObjectNotFoundError) do |e|
    render status: :not_found, plain: e.message
  end

  # Show administrative tags for an object
  def index
    render json: AdministrativeTags.for(identifier: params[:object_id])
  end

  def search
    results = TagLabel.where('tag like ?', "#{params[:q]}%").limit(10).pluck(:tag)
    render json: results
  end

  def create # rubocop:disable Metrics/AbcSize
    AdministrativeTags.create(identifier: params[:object_id],
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
    Indexer.reindex_later(druid: @cocina_object.externalIdentifier)
    head :created
  end

  def update # rubocop:disable Metrics/AbcSize
    AdministrativeTags.update(identifier: params[:object_id],
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
    Indexer.reindex_later(druid: @cocina_object.externalIdentifier)
    head :no_content
  end

  def destroy
    AdministrativeTags.destroy(identifier: params[:object_id], tag: CGI.unescape(params[:id]))
  rescue ActiveRecord::RecordNotFound => e
    render status: :not_found, plain: e.message
  else
    Indexer.reindex_later(druid: @cocina_object.externalIdentifier)
  end
end
