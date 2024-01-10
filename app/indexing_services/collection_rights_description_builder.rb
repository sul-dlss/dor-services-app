# frozen_string_literal: true

# Rights description builder for collections
class CollectionRightsDescriptionBuilder
  def self.build(cocina)
    new(cocina).build
  end

  def initialize(cocina)
    @cocina = cocina
  end

  def build
    case cocina.access.view
    when 'world'
      'world'
    else
      'dark'
    end
  end

  private

  attr_reader :cocina
end
