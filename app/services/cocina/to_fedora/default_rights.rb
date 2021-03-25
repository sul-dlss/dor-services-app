# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the AdminPolicyDefaultAccess schema to the
    # Fedora 3 data model defaultObjectRights
    class DefaultRights
      # These codes are the only codes accepted by DefaultObjectRightsDS#use_license=
      # so we can't just add to this list without updating that method.
      # https://github.com/sul-dlss/dor-services/blob/main/lib/dor/services/creative_commons_license_service.rb
      # https://github.com/sul-dlss/dor-services/blob/main/lib/dor/services/open_data_license_service.rb
      LICENSE_CODES = {
        nil => nil,
        'https://creativecommons.org/licenses/by/3.0/' => 'by',
        'https://creativecommons.org/licenses/by-sa/3.0/' => 'by-sa',
        'https://creativecommons.org/licenses/by-nd/3.0/' => 'by-nd',
        'https://creativecommons.org/licenses/by-nc/3.0/' => 'by-nc',
        'https://creativecommons.org/licenses/by-nc-sa/3.0/' => 'by-nc-sa',
        'https://creativecommons.org/licenses/by-nc-nd/3.0/' => 'by-nc-nd',
        'https://creativecommons.org/publicdomain/mark/1.0/' => 'pdm',
        'http://opendatacommons.org/licenses/pddl/1.0/' => 'pddl',
        'http://opendatacommons.org/licenses/by/1.0/' => 'odc-by',
        'http://opendatacommons.org/licenses/odbl/1.0/' => 'odc-odbl'
      }.freeze

      def self.write(default_object_rights_ds, default_access)
        default_object_rights_ds.default_rights = Rights.rights_type(default_access)
        default_object_rights_ds.use_license = LICENSE_CODES.fetch(default_access.license)
        default_object_rights_ds.copyright_statement = default_access.copyright
        default_object_rights_ds.use_statement = default_access.useAndReproductionStatement
      end
    end
  end
end
