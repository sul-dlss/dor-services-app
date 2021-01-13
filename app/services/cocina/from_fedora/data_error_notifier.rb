# frozen_string_literal: true

module Cocina
  module FromFedora
    # Notifies when a data error is encountered. Notification is performed with Honeybadger.
    class DataErrorNotifier
      # In addition, it distinguishes between warnings and errors, even if both are notified the same.
      # The determination of warn / error is currently made by the metadata team.

      # @param [String] druid
      def initialize(druid:)
        @druid = druid
      end

      # Notify for a non-critical data error.
      # @param [String] message
      # @param [Hash<String, String>] context to add to warning context
      def warn(message, context = {})
        return unless Settings.from_fedora_data_errors.notify_warn

        Honeybadger.notify("[DATA WARNING] #{message}",
                           tags: 'data_warning',
                           context: { druid: druid }.merge(context))
      end

      # Notify for a critical data error.
      # @param [String] message
      # @param [Hash<String, String>] context to add to error context
      def error(message, context = {})
        return unless Settings.from_fedora_data_errors.notify_error

        Honeybadger.notify("[DATA ERROR] #{message}",
                           tags: 'data_error',
                           context: { druid: druid }.merge(context))
      end

      private

      attr_reader :druid
    end
  end
end
