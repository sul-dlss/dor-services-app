# frozen_string_literal: true

class CreateBackgroundJobResults < ActiveRecord::Migration[5.2]
  def up
    execute <<-SQL
      CREATE TYPE background_job_result_status AS ENUM (
        'pending', 'processing', 'complete'
      );
    SQL

    create_table :background_job_results do |t|
      t.text :output
      t.integer :code, default: 202
      t.column :status, :background_job_result_status, default: 'pending'

      t.timestamps
    end
  end

  def down
    drop_table :background_job_results
    execute 'DROP TYPE background_job_result_status;'
  end
end
