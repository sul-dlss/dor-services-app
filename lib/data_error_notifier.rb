# frozen_string_literal: true

# Notifies when a data error is encountered. Notifications are collected.
class DataErrorNotifier
  DataError = Struct.new(:msg, :context)
  def initialize
    @data_errors = []
  end

  # Notify for a non-critical data error.
  # @param [String] message
  # @param [Hash<String, String>] context to add to warning context
  def warn(message, context = {})
    data_errors << DataError.new(message, context)
  end

  # Notify for a critical data error.
  # @param [String] message
  # @param [Hash<String, String>] context to add to error context
  def error(message, context = {})
    data_errors << DataError.new(message, context)
  end

  def error?
    data_errors.present?
  end

  attr_reader :data_errors
end
