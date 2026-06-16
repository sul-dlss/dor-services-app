# frozen_string_literal: true

module Migrators
  # Removes a nested identifier property from description in all objects and versions.
  # For example:
  # "identifier" =>
  # [{"note" => [],
  #   "type" => "local",
  #   "value" => "sul-chs:PC010_09_1009",
  #   "appliesTo" => [],
  #   "identifier" => [], <-- nested identifier to be removed
  #   "displayLabel" => "Source ID",
  #   "groupedValue" => [],
  #   "parallelValue" => [],
  #   "structuredValue" => []}]
  # See parent class and Migrators::MigrationRunner for more information.
  class RemoveNestedIdentifier < Base
    def migrate
      remove_from_hash(hash: model_hash['description'], nested: false)

      model_hash
    end

    private

    def remove_from_hash(hash:, nested: false)
      hash.delete('identifier') if nested

      hash.each do |key, value|
        next unless value.is_a?(Array)

        value.each do |item|
          remove_from_hash(hash: item, nested: key == 'identifier') if item.is_a?(Hash)
        end
      end
    end
  end
end
