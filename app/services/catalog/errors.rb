# frozen_string_literal: true

module Catalog
  module Errors
    class BaseError < RuntimeError; end
    class ResponseError < BaseError; end
    class RecordNotFoundError < BaseError; end
  end
end
