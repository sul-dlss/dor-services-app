# frozen_string_literal: true

module Cocina
  module FromMarc
    # Creates Cocina Description objects from MARC records
    class DescriptionBuilder
      BUILDERS = {
        title: Title,
        note: Note,
        language: Language,
        contributor: Contributor,
        event: Event,
        subject: Subject,
        form: Form,
        identifier: Identifier,
        adminMetadata: AdminMetadata,
        relatedResource: RelatedResource,
        geographic: Geographic,
        access: Access
      }.freeze

      # @param [MARC::Record] marc MARC record from FOLIO
      # @param [Cocina::Models::Mapping::ErrorNotifier] notifier
      # @param [String] purl
      # @return [Hash] a hash that can be mapped to a Cocina Description model
      def self.build(marc:, notifier:, purl: nil)
        new(notifier: notifier).build(marc: marc, purl: purl)
      end

      def initialize(notifier:)
        @notifier = notifier
      end

      # @return [Hash, nil] a hash that can be mapped to a Cocina Description model
      def build(marc:, purl: nil) # rubocop:disable Metrics/CyclomaticComplexity
        BUILDERS.filter_map do |description_property, builder|
          kwargs = { marc: }
          has_notifier = builder.method(:build).parameters.map(&:second).include?(:notifier)
          kwargs[:notifier] = notifier if has_notifier

          result = builder.build(**kwargs)
          break if result.nil? && has_notifier

          { description_property => result } if result.present?
        end&.reduce({ purl: }, :merge)
      end

      private

      attr_reader :notifier
    end
  end
end
