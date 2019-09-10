# frozen_string_literal: true

class SdrController < ApplicationController
  def cm_inv_diff
    unless %w(all shelve preserve publish).include?(params[:subset].to_s)
      render status: :bad_request, plain: "Invalid subset value: #{params[:subset]}"
      return
    end

    request.body.rewind
    current_content = request.body.read

    query_params = { subset: params[:subset].to_s }
    query_params[:version] = params[:version].to_s unless params[:version].nil?
    query_string = URI.encode_www_form(query_params)
    url = "#{Settings.sdr_url}/objects/#{params[:druid]}/cm-inv-diff?#{query_string}"
    sdr_response = Faraday.post(url, current_content, 'Content-Type' => 'application/xml')

    proxy_faraday_response(sdr_response)
  end

  def ds_manifest
    url = "#{Settings.sdr_url}/objects/#{params[:druid]}/manifest/#{params[:dsname]}"
    sdr_response = Faraday.get url

    proxy_faraday_response(sdr_response)
  end

  def ds_metadata
    url = "#{Settings.sdr_url}/objects/#{params[:druid]}/metadata/#{params[:dsname]}"
    sdr_response = Faraday.get url

    proxy_faraday_response(sdr_response)
  end

  def current_version
    url = "#{Settings.sdr_url}/objects/#{params[:druid]}/current_version"
    sdr_response = Faraday.get url

    proxy_faraday_response(sdr_response)
  end

  def file_content
    query_string = URI.encode_www_form(version: params[:version].to_s)
    encoded_filename = URI.encode(params[:filename])
    url = "#{Settings.sdr_url}/objects/#{params[:druid]}/content/#{encoded_filename}?#{query_string}"
    sdr_response = Faraday.get url

    proxy_faraday_response(sdr_response)
  end
end
