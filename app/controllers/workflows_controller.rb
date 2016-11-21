class WorkflowsController < ApplicationController
  before_action :load_item, except: [:initial]

  def initial
    render content_type: 'application/xml', body: Dor::WorkflowObject.initial_workflow(params[:wf_name])
  end
  
  def archive
    version = params.fetch(:ver_num) { @item.current_version }
    archiver.archive_one_datastream 'dor', params[:object_id], params[:id], version
    
    render plain: "#{params[:id]} version #{version} archived"
  end
  
  private

  def load_item
    @item = Dor.find(params[:id])
  end

  def archiver
    Dor::WorkflowArchiver.new
  end
end
