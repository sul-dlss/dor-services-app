# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_item

  def create
    VersionService.open(@item, open_params)
    render plain: @item.current_version
  rescue Dor::Exception => e
    render build_error('Unable to open version', e)
  end

  def current
    render plain: @item.current_version
  end

  def close_current
    VersionService.close(@item, close_params)
    render plain: "version #{@item.current_version} closed"
  rescue Dor::Exception => e
    render build_error('Unable to close version', e)
  end

  def openable
    render plain: VersionService.can_open?(@item, open_params).to_s
  end

  private

  # JSON-API error response
  def build_error(msg, err)
    {
      json: {
        errors: [
          {
            "status": '422',
            "title": msg,
            "detail": err.message
          }
        ]
      },
      content_type: 'application/vnd.api+json',
      status: :unprocessable_entity
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
