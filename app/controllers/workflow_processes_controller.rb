# frozen_string_literal: true

# Controller for workflow processes
class WorkflowProcessesController < WorkflowApplicationController
  def show
    status = workflow_client.workflow_status(druid:, workflow:, process: workflow_process)
    render json: { status: }
  end

  def update # rubocop:disable Metrics/AbcSize
    if status == 'error'
      workflow_client.update_error_status(druid:, workflow:, process: workflow_process, error_msg: params[:error_msg],
                                          error_text: params[:error_text])
    else
      workflow_client.update_status(druid:, workflow:, process: workflow_process, status:,
                                    elapsed: params[:elapsed] || 0, lifecycle: params[:lifecycle], note: params[:note],
                                    current_status: params[:current_status])
    end

    head :no_content
  end

  private

  def druid
    params[:object_id]
  end

  def workflow
    params[:workflow_id]
  end

  def workflow_process
    params[:id]
  end

  def status
    params[:status]
  end
end
