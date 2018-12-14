# API to retrieve file listings and file content from the DOR workspace
class ContentController < ApplicationController
  rescue_from ActionController::MissingFile do
    render status: :not_found
  end

  def read
    location = druid_tools.find(:content, params[:path])
    return render status: :not_found unless location
    send_file location
  end

  def list
    location = druid_tools.content_dir(false)

    raise ActionController::MissingFile, location unless Dir.exist? location

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

  def druid_tools
    DruidTools::Druid.new(params[:id], Dor::Config.content.content_base_dir)
  end
end
