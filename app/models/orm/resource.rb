# frozen_string_literal: true

module Orm
  # ActiveRecord class which the Postgres adapter uses for persisting data.
  # @!attribute id
  #   @return [UUID] ID of the record
  # @!attribute metadata
  #   @return [Hash] Hash of all metadata.
  # @!attribute created_at
  #   @return [DateTime] Date created
  # @!attribute updated_at
  #   @return [DateTime] Date updated
  # @!attribute internal_resource
  #   @return [String] Name of {Valkyrie::Resource} model - used for casting.
  #
  class Resource < ApplicationRecord
    self.table_name = 'orm_resources'
  end
end
