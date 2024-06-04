# frozen_string_literal: true

module Migrators
  # Migrator that will be used to remove release tags.
  class RemoveReleaseTags < Base
    def migrate?
      repository_object.head_version.administrative.key?('releaseTags')
    end

    def migrate
      repository_object.head_version.administrative.delete('releaseTags')
    end
  end
end
