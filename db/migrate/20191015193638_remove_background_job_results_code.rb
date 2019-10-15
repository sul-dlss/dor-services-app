class RemoveBackgroundJobResultsCode < ActiveRecord::Migration[5.2]
  def change
    remove_column :background_job_results, :code
  end
end
