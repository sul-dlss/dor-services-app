# frozen_string_literal: true

class RightsMetadataIndexer
  attr_reader :cocina

  def initialize(cocina:, **)
    @cocina = cocina
  end

  # @return [Hash] the partial solr document for rightsMetadata
  def to_solr
    Rails.logger.debug { "In #{self.class}" }

    {
      'copyright_ssim' => cocina.access.copyright,
      'use_statement_ssim' => cocina.access.useAndReproductionStatement,
      'use_license_machine_ssi' => license,
      'rights_descriptions_ssim' => rights_description
    }.compact
  end

  private

  LICENSE_CODE = {
    'http://cocina.sul.stanford.edu/licenses/none' => 'none', # Only used in some legacy ETDs.
    'https://creativecommons.org/licenses/by/3.0/legalcode' => 'CC-BY-3.0',
    'https://creativecommons.org/licenses/by-sa/3.0/legalcode' => 'CC-BY-SA-3.0',
    'https://creativecommons.org/licenses/by-nd/3.0/legalcode' => 'CC-BY-ND-3.0',
    'https://creativecommons.org/licenses/by-nc/3.0/legalcode' => 'CC-BY-NC-3.0',
    'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' => 'CC-BY-NC-SA-3.0',
    'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode' => 'CC-BY-NC-ND-3.0',
    'https://creativecommons.org/licenses/by/4.0/legalcode' => 'CC-BY-4.0',
    'https://creativecommons.org/licenses/by-sa/4.0/legalcode' => 'CC-BY-SA-4.0',
    'https://creativecommons.org/licenses/by-nd/4.0/legalcode' => 'CC-BY-ND-4.0',
    'https://creativecommons.org/licenses/by-nc/4.0/legalcode' => 'CC-BY-NC-4.0',
    'https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode' => 'CC-BY-NC-SA-4.0',
    'https://creativecommons.org/licenses/by-nc-nd/4.0/legalcode' => 'CC-BY-NC-ND-4.0',
    'https://creativecommons.org/publicdomain/zero/1.0/legalcode' => 'CC0-1.0',
    'https://creativecommons.org/publicdomain/mark/1.0/' => 'PDM',
    'https://opendatacommons.org/licenses/pddl/1-0/' => 'PDDL-1.0',
    'https://opendatacommons.org/licenses/by/1-0/' => 'ODC-By-1.0',
    'https://opendatacommons.org/licenses/odbl/1-0/' => 'ODbL-1.0'
  }.freeze

  def rights_description
    return CollectionRightsDescriptionBuilder.build(cocina) if cocina.collection?

    Cocina::Models::Builders::DroRightsDescriptionBuilder.build(cocina)
  end

  # @return [String] the code if we've defined one, or the URI if we haven't.
  def license
    uri = cocina.access.license
    LICENSE_CODE.fetch(uri, uri)
  end
end
