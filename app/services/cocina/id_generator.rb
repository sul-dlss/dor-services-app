# frozen_string_literal: true

module Cocina
  # Generates identifiers for use within Cocina model.
  class IdGenerator
    ID_NAMESPACE = 'http://cocina.sul.stanford.edu/'

    def self.generate_fileset_id
      generate_id('fileSet')
    end

    def self.generate_or_existing_fileset_id(existing_id)
      cocina_id?(existing_id) ? existing_id : generate_fileset_id
    end

    def self.generate_file_id
      generate_id('file')
    end

    def self.generate_or_existing_file_id(existing_id)
      cocina_id?(existing_id) ? existing_id : generate_file_id
    end

    def self.cocina_id?(id)
      id.present? && id.start_with?(ID_NAMESPACE)
    end

    def self.generate_id(type)
      "#{ID_NAMESPACE}#{type}/#{SecureRandom.uuid}"
    end
    private_class_method :generate_id
  end
end
