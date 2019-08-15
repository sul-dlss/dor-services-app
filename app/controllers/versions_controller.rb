# frozen_string_literal: true

class VersionsController < ApplicationController
  extend Deprecation
  self.deprecation_horizon = 'dor-services-app 3.0.0'

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

  def openeable
    openable
  end
  deprecation_deprecate openeable: 'use openable instead'

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
      vers_md_upd_info: [
        :description,
        :opening_user_name,
        :significance
      ]
    ).to_h.deep_symbolize_keys
  end

  def close_params
    symbolized_hash = params.permit(
      :description,
      :significance,
      :start_accession,
      :version_num
    ).to_h.symbolize_keys
    # Downstream code expects the significance value to be a symbol
    symbolized_hash[:significance] = symbolized_hash[:significance].to_sym if symbolized_hash.key?(:significance)
    symbolized_hash
  end
end
