# frozen_string_literal: true

# Service for finding virtual object membership
class VirtualObject
  # Find virtual objects that this item is a constituent of
  # @param [String] druid
  # @return [Array<Hash>] a list of results with ids and titles
  def self.for(druid:)
    Dro.in_virtual_objects(druid).map do |dro|
      {
        id: dro.external_identifier,
        title: Cocina::Models::Builders::TitleBuilder.build(dro.to_cocina.description.title)
      }
    end
  end
end
