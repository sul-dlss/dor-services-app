# frozen_string_literal: true

module Cocina
  # Raised when a roundtrip validation fails
  class RoundtripValidationError < ValidationError
    def initialize(message)
      super(message, status: :unprocessable_entity)
    end
  end
end
