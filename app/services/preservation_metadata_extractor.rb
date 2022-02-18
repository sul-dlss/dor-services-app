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
  # @param [Hash<Symbol,Bool>] datastream_config the list of datastreams to export and whether they are required or not.
  def initialize(cocina_object:, workspace:, datastream_config: DEFAULT_DATASTREAM_CONFIG)
    @cocina_object = cocina_object
    @datastream_config = datastream_config
    @metadata_dir = Pathname.new(workspace.path('metadata', true))
  end

  # @return [Pathname] metadata directory
  def extract
    extract_datastreams
    extract_cocina
    metadata_dir
  end

  private

  attr_reader :metadata_dir, :datastream_config, :cocina_object

  # Which datastreams to export and whether they are required or not
  DEFAULT_DATASTREAM_CONFIG =
    {
      administrativeMetadata: false,
      contentMetadata: false,
      descMetadata: true,
      defaultObjectRights: false,
      events: false,
      embargoMetadata: false,
      identityMetadata: true,
      provenanceMetadata: false,
      relationshipMetadata: true,
      rightsMetadata: false,
      roleMetadata: false,
      sourceMetadata: false,
      versionMetadata: true,
      workflows: false,
      geoMetadata: false
    }.freeze

  # Pull all the datastreams specified in the configuration file
  #   into the workspace's metadata directory, overwriting existing file if present
  def extract_datastreams
    item = Dor.find(cocina_object.externalIdentifier)
    datastream_config.each do |ds_name, required|
      metadata_file = metadata_dir.join("#{ds_name}.xml")
      metadata_string = datastream_content(item, ds_name, required)
      metadata_file.open('w') { |f| f << metadata_string } if metadata_string
    end
  end

  # @param [Symbol] ds_name The name of the desired Fedora datastream
  # @param [Boolean] required is the datastream required
  # @return [String] return the xml text of the specified datastream if it exists.
  #   If not found, return nil unless it is a required datastream in which case raise exception
  def datastream_content(item, ds_name, required)
    ds = (ds_name == :relationshipMetadata ? 'RELS-EXT' : ds_name.to_s)
    return workflow_xml if ds_name == :workflows
    return version_xml(item) if ds_name == :versionMetadata
    return content_xml if ds_name == :contentMetadata
    return item.datastreams[ds].content if item.datastreams.key?(ds) && !item.datastreams[ds].new?

    raise "required datastream #{ds_name} for #{item.pid} not found in DOR" if required
  end

  # Get the workflow xml representation from the workflow service
  def workflow_xml
    WorkflowClientFactory.build.all_workflows_xml(cocina_object.externalIdentifier)
  end

  def version_xml(item)
    # This can be removed after migration.
    VersionMigrationService.migrate(item)

    ObjectVersion.version_xml(cocina_object.externalIdentifier)
  end

  def content_xml
    Cocina::ToFedora::ContentMetadataGenerator.generate(druid: cocina_object.externalIdentifier,
                                                        structural: cocina_object.structural, type: cocina_object.type)
  end

  def extract_cocina
    metadata_file = metadata_dir.join('cocina.json')
    metadata_file.open('w') do |f|
      f << JSON.pretty_generate(cocina_object.to_h)
    end
  end
end
