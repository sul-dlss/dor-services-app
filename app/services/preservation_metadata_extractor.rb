# frozen_string_literal: true

# This writes the object metadata files to the workspace metadata directory
class PreservationMetadataExtractor
  # @param [Cocina::Models::DRO, Cocina::Models::AdminPolicy, Cocina::Models::Collection] cocina_object The representation of the digital object
  # @param [DruidTools::Druid] workspace The representation of the item's work area
  # @return [Pathname] Pull all the datastreams specified in the configuration file
  #   into the workspace's metadata directory, overwriting existing file if present
  def self.extract(cocina_object:, workspace:)
    new(workspace: workspace, cocina_object: cocina_object).extract
  end

  # @param [Cocina::Models::DRO, Cocina::Models::AdminPolicy, Cocina::Models::Collection] cocina_object The representation of the digital object
  # @param [DruidTools::Druid] workspace The representation of the item's work area
  def initialize(cocina_object:, workspace:)
    @cocina_object = cocina_object
    @metadata_dir = Pathname.new(workspace.path('metadata', true))
  end

  # @return [Pathname] metadata directory
  def extract
    generate_xml
    extract_cocina
    metadata_dir
  end

  private

  attr_reader :metadata_dir, :cocina_object

  # Generate all the required xml files
  def generate_xml
    versions_file = metadata_dir.join('versionMetadata.xml')
    versions_file.open('w') { |f| f << version_xml }

    content_file = metadata_dir.join('contentMetadata.xml')
    content_file.open('w') { |f| f << content_xml }
  end

  def version_xml
    ObjectVersion.version_xml(cocina_object.externalIdentifier)
  end

  def content_xml
    return if cocina_object.admin_policy? || cocina_object.collection?

    Cocina::ToXml::ContentMetadataGenerator.generate(druid: cocina_object.externalIdentifier, structural: cocina_object.structural, type: cocina_object.type)
  end

  def extract_cocina
    metadata_file = metadata_dir.join('cocina.json')
    metadata_file.open('w') do |f|
      f << JSON.pretty_generate(cocina_object.to_h)
    end
  end
end
