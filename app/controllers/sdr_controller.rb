# frozen_string_literal: true

class SdrController < ApplicationController
  extend Deprecation
  self.deprecation_horizon = 'dor-services-app version 4.0'

  MANIFEST_DEPRECATION_MESSAGE = 'Use preservation-client manifest or signature_catalog in caller instead.'
  CURRENT_VERSION_DEPRECATION_MESSAGE = 'Use preservation-client current_version in caller instead.'
  CM_INV_DIFF_DEPRECATION_MESSAGE = 'Use preservation-client content_inventory_diff or shelve_content_diff in caller instead.'

  def cm_inv_diff
    Honeybadger.notify("dor-services-app deprecated API endpoint `sdr#cm_inv_diff` called. #{CM_INV_DIFF_DEPRECATION_MESSAGE}")
    unless %w(all shelve preserve publish).include?(params[:subset])
      render status: :bad_request, plain: "Invalid subset value: #{params[:subset]}"
      return
    end

    request.body.rewind
    current_content = request.body.read

    sdr_response = sdr_client.content_diff(current_content: current_content, subset: params[:subset], version: params[:version])
    proxy_faraday_response(sdr_response)
  end
  deprecation_deprecate cm_inv_diff: CM_INV_DIFF_DEPRECATION_MESSAGE

  # Deprecated
  def ds_manifest
    Honeybadger.notify("dor-services-app deprecated API endpoint `sdr#ds_manifest` called. #{MANIFEST_DEPRECATION_MESSAGE}")
    sdr_response = sdr_client.manifest(ds_name: params[:dsname])
    proxy_faraday_response(sdr_response)
  end
  deprecation_deprecate ds_manifest: MANIFEST_DEPRECATION_MESSAGE

  def ds_metadata
    sdr_response = sdr_client.metadata(ds_name: params[:dsname])
    proxy_faraday_response(sdr_response)
  end

  def current_version
    Honeybadger.notify("dor-services-app deprecated API endpoint `sdr#current_version` called. #{CURRENT_VERSION_DEPRECATION_MESSAGE}")
    proxy_faraday_response(sdr_client.current_version)
  end
  deprecation_deprecate current_version: CURRENT_VERSION_DEPRECATION_MESSAGE

  def file_content
    sdr_response = sdr_client.file_content(version: params[:version], filename: params[:filename])
    proxy_faraday_response(sdr_response)
  end

  private

  def sdr_client
    SdrClient.new(params[:druid])
  end
end
