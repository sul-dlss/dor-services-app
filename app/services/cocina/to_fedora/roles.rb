# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the AdminPolicyAdministrative schema to the
    # Fedora 3 roles
    class Roles
      def self.write(apo, roles)
        apo.purge_roles
        roles.each do |role|
          role.members.each do |member|
            apo.add_roleplayer(role.name, member.identifier, member.type.to_sym)
          end
        end
      end
    end
  end
end
