# frozen_string_literal: true

# API to retrieve file listings and file content from the DOR workspace
class ContentController < ApplicationController
  def read
    location = druid_tools.find(:content, params[:path])
    return not_found(location) unless location

    send_file location
  end

  def list
    location = druid_tools.content_dir(false)

    return not_found(location) unless Dir.exist? location

    render json: {
      items: Dir.glob(File.join(location, '**', '*')).map do |file|
        path = file.sub(location + '/', '')
        {
          id: path,
          name: path,
          selfLink: read_content_object_url(id: params[:id], path: path)
        }
      end
    }
  end

  private

  def not_found(location)
    render status: :not_found, plain: "Unable to locate file #{location}"
  end

  def druid_tools
    DruidTools::Druid.new(params[:id], Settings.content.content_base_dir)
  end
end
