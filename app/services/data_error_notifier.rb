# frozen_string_literal: true

# Notifies when a data error is encountered. Notification is performed with Honeybadger.
class DataErrorNotifier
  # @param [String] druid
  def initialize(druid:)
    @druid = druid
  end

  # Notify for a critical data error.
  # @param [String] message
  # @param [Hash<String, String>] context to add to error context
  def error(message, context = {})
    Honeybadger.notify("[DATA ERROR] #{message}",
                       tags: 'data_error',
                       context: { druid: }.merge(context))
  end

  private

  attr_reader :druid
end
