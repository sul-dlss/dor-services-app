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
    path = "/objects/#{params[:druid]}/cm-inv-diff"
    uri = sdr_uri(path)
    sdr_response = sdr_conn(uri).post("#{uri.path}?#{query_string}", current_content, 'Content-Type' => 'application/xml')

    proxy_faraday_response(sdr_response)
  end

  def ds_manifest
    proxy_faraday_response(sdr_get("/objects/#{params[:druid]}/manifest/#{params[:dsname]}"))
  end

  def ds_metadata
    proxy_faraday_response(sdr_get("/objects/#{params[:druid]}/metadata/#{params[:dsname]}"))
  end

  def current_version
    proxy_faraday_response(sdr_get("/objects/#{params[:druid]}/current_version"))
  end

  def file_content
    query_string = URI.encode_www_form(version: params[:version].to_s)
    encoded_filename = URI.encode(params[:filename])
    proxy_faraday_response(sdr_get("/objects/#{params[:druid]}/content/#{encoded_filename}?#{query_string}"))
  end

  private

  def sdr_uri(path)
    URI("#{Settings.sdr_url}#{path}")
  end

  def sdr_conn(uri)
    Faraday.new("#{uri.scheme}://#{uri.host}").tap do |conn|
      conn.basic_auth(uri.user, uri.password)
    end
  end

  def sdr_get(path)
    uri = sdr_uri(path)
    sdr_conn(uri).get("#{uri.path}?#{uri.query}")
  end
end
