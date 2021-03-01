# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_item

  def create
    VersionService.open(@item, open_params, event_factory: EventFactory)
    render plain: @item.current_version
  rescue Dor::Exception => e
    render build_error('Unable to open version', e)
  rescue Preservation::Client::Error => e
    render build_error('Unable to open version due to preservation client error', e, status: :internal_server_error)
  end

  def current
    render plain: @item.current_version
  end

  def close_current
    VersionService.close(@item, close_params, event_factory: EventFactory)
    render plain: "version #{@item.current_version} closed"
  rescue Dor::Exception => e
    render build_error('Unable to close version', e)
  end

  def openable
    render plain: VersionService.can_open?(@item, open_params).to_s
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

  def open_params
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
      :user_name,
      :version_num
    ).to_h.symbolize_keys
  end
end
