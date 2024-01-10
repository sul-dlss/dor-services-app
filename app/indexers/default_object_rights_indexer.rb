# frozen_string_literal: true

class DefaultObjectRightsIndexer
  attr_reader :cocina

  def initialize(cocina:, **)
    @cocina = cocina
  end

  # @return [Hash] the partial solr document for defaultObjectRights
  def to_solr
    return {} unless cocina.administrative.accessTemplate

    {
      'use_statement_ssim' => use_statement,
      'copyright_ssim' => copyright,
      'rights_descriptions_ssim' => 'dark',
      'default_rights_descriptions_ssim' => Cocina::Models::Builders::RightsDescriptionBuilder.build(cocina)
    }
  end

  private

  def use_statement
    cocina.administrative.accessTemplate.useAndReproductionStatement
  end

  def copyright
    cocina.administrative.accessTemplate.copyright
  end
end
