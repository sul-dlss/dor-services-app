# frozen_string_literal: true

class AuthorBuilder
  def initialize(cocina_contributors)
    @cocina_contributors = Array(cocina_contributors)
  end

  def build_primary
    contributor = primary_cocina_contributor || cocina_contributors.first
    return unless contributor

    NameBuilder.build_primary_name(contributor.name) if contributor
  end

  def build_all
    NameBuilder.build_all(cocina_contributors.filter_map(&:name))
  end

  private

  attr_reader :cocina_contributors

  def primary_cocina_contributor
    cocina_contributors.find { |cocina_contributor| cocina_contributor.status == 'primary' }
  end
end
