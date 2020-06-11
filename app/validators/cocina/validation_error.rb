# frozen_string_literal: true

module Cocina
  # Raised when a validation fails
  class ValidationError < StandardError
    def initialize(message, status: :bad_request)
      super(message)
      @status = status
    end

    attr_reader :status
  end
end
