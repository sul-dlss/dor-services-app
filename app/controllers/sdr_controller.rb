# frozen_string_literal: true

class SdrController < ApplicationController
  extend Deprecation
  self.deprecation_horizon = 'dor-services-app version 4.0'

  def cm_inv_diff
    unless %w(all shelve preserve publish).include?(params[:subset])
      render status: :bad_request, plain: "Invalid subset value: #{params[:subset]}"
      return
    end

    request.body.rewind
    current_content = request.body.read

    sdr_response = sdr_client.content_diff(current_content: current_content, subset: params[:subset], version: params[:version])
    proxy_faraday_response(sdr_response)
  end

  # Deprecated
  def ds_manifest
    sdr_response = sdr_client.manifest(ds_name: params[:dsname])
    proxy_faraday_response(sdr_response)
  end

  def ds_metadata
    sdr_response = sdr_client.metadata(ds_name: params[:dsname])
    proxy_faraday_response(sdr_response)
  end

  def current_version
    Honeybadger.notify('dor-services-app deprecated API endpoint `sdr#current_version` called - use preservation-client current_version instead')
    proxy_faraday_response(sdr_client.current_version)
  end
  deprecation_deprecate current_version: 'use preservation-client current_version in caller instead'

  def file_content
    sdr_response = sdr_client.file_content(version: params[:version], filename: params[:filename])
    proxy_faraday_response(sdr_response)
  end

  private

  def sdr_client
    SdrClient.new(params[:druid])
  end
end
