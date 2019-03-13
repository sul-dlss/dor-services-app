class SdrController < ApplicationController
  def cm_inv_diff
    unless %w(all shelve preserve publish).include?(params[:subset].to_s)
      render status: 400, plain: "Invalid subset value: #{params[:subset]}"
      return
    end

    request.body.rewind
    current_content = request.body.read

    query_params = { subset: params[:subset].to_s }
    query_params[:version] = params[:version].to_s unless params[:version].nil?
    query_string = URI.encode_www_form(query_params)
    sdr_query = "objects/#{params[:druid]}/cm-inv-diff?#{query_string}"

    sdr_response = sdr_client[sdr_query].post(current_content, content_type: 'application/xml') { |response, _request, _result| response }
    proxy_rest_client_response(sdr_response)
  end

  def ds_manifest
    url = "objects/#{params[:druid]}/manifest/#{params[:dsname]}"
    sdr_response = sdr_client[url].get { |response, _request, _result| response }
    proxy_rest_client_response(sdr_response)
  end

  def ds_metadata
    url = "objects/#{params[:druid]}/metadata/#{params[:dsname]}"
    sdr_response = sdr_client[url].get { |response, _request, _result| response }
    proxy_rest_client_response(sdr_response)
  end

  def current_version
    sdr_response = sdr_client["objects/#{params[:druid]}/current_version"].get { |response, _request, _result| response }
    proxy_rest_client_response(sdr_response)
  end

  def file_content
    query_string = URI.encode_www_form(version: params[:version].to_s)
    encoded_filename = URI.encode(params[:filename])
    url = "objects/#{params[:druid]}/content/#{encoded_filename}?#{query_string}"
    sdr_response = sdr_client[url].get { |response, _request, _result| response }
    proxy_rest_client_response(sdr_response)
  end

  private

  def sdr_client
    Dor::Config.sdr.rest_client
  end
end
