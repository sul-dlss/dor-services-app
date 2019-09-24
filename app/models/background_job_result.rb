# frozen_string_literal: true

# Database-backed model to hold results of long-running jobs
class BackgroundJobResult < ApplicationRecord
  enum status: {
    pending: 'pending',
    processing: 'processing',
    complete: 'complete'
  }
end
