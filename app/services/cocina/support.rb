# frozen_string_literal: true

module Cocina
  # Support methods for Cocina models
  class Support
    def self.dark?(cocina_object)
      raise 'APOs do not have access properties' if cocina_object.admin_policy?

      cocina_object.access.view == 'dark'
    end

    def self.agreement?(cocina_object)
      cocina_object.type == Cocina::Models::ObjectType.agreement
    end

    def self.virtual_object?(cocina_object)
      cocina_object.dro? && cocina_object.structural&.hasMemberOrders&.first&.members.present?
    end
  end
end
