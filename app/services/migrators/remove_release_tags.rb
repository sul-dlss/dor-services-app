# frozen_string_literal: true

module Migrators
  # Migrator that will be used to remove release tags.
  class RemoveReleaseTags < Base
    def migrate?
      repository_object.versions.any? { |version| version.administrative&.key?('releaseTags') }
    end

    def migrate
      repository_object.versions.select { |version| version.administrative&.key?('releaseTags') }.each do |version|
        version.administrative.delete('releaseTags')
      end
    end
  end
end
