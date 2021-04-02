# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the AdminPolicyDefaultAccess schema to the
    # Fedora 3 data model defaultObjectRights
    class DefaultRights
      def self.write(default_object_rights_ds, default_access)
        License.update(default_object_rights_ds, default_access.license)
        default_object_rights_ds.default_rights = Rights.rights_type(default_access)
        default_object_rights_ds.copyright_statement = default_access.copyright
        default_object_rights_ds.use_statement = default_access.useAndReproductionStatement
      end
    end
  end
end
