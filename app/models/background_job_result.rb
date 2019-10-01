# frozen_string_literal: true

# Database-backed model to hold results of long-running jobs
class BackgroundJobResult < ApplicationRecord
  enum status: {
    pending: 'pending',
    processing: 'processing',
    complete: 'complete'
  }

  # Deserialize JSON output field as a Hash with indifferent access
  def output
    @output ||= super.with_indifferent_access
  end
end
