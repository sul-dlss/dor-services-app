# frozen_string_literal: true

# This writes the contents of datastreams to the workspace metadata directory
class DatastreamExtractor
  # @param [Dor::Item] item The representation of the digital object
  # @param [DruidTools::Druid] workspace The representation of the item's work area
  # @return [Pathname] Pull all the datastreams specified in the configuration file
  #   into the workspace's metadata directory, overwriting existing file if present
  def self.extract_datastreams(item:, workspace:)
    new(item: item, workspace: workspace).extract_datastreams
  end

  # @param [Dor::Item] item The representation of the digital object
  # @param [DruidTools::Druid] workspace The representation of the item's work area
  # @param [Hash<Symbol,Bool>] datastream_config the list of datastreams to export and whether they are required or not.
  def initialize(item:, workspace:, datastream_config: DEFAULT_DATASTREAM_CONFIG)
    @item = item
    @datastream_config = datastream_config
    @metadata_dir = Pathname.new(workspace.path('metadata', true))
  end

  # @return [Pathname] Pull all the datastreams specified in the configuration file
  #   into the workspace's metadata directory, overwriting existing file if present
  def extract_datastreams
    datastream_config.each do |ds_name, required|
      metadata_file = metadata_dir.join("#{ds_name}.xml")
      metadata_string = datastream_content(ds_name, required)
      metadata_file.open('w') { |f| f << metadata_string } if metadata_string
    end
    metadata_dir
  end

  private

  attr_reader :metadata_dir, :item, :datastream_config

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
      provenanceMetadata: true,
      relationshipMetadata: true,
      rightsMetadata: false,
      roleMetadata: false,
      sourceMetadata: false,
      versionMetadata: true,
      workflows: false,
      geoMetadata: false
    }.freeze

  # @param [Symbol] ds_name The name of the desired Fedora datastream
  # @param [Boolean] required is the datastream required
  # @return [String] return the xml text of the specified datastream if it exists.
  #   If not found, return nil unless it is a required datastream in which case raise exception
  def datastream_content(ds_name, required)
    ds = (ds_name == :relationshipMetadata ? 'RELS-EXT' : ds_name.to_s)
    return workflow_xml if ds_name == :workflows
    return item.datastreams[ds].content if item.datastreams.key?(ds) && !item.datastreams[ds].new?

    raise "required datastream #{ds_name} for #{item.pid} not found in DOR" if required
  end

  # Get the workflow xml representation from the workflow service
  def workflow_xml
    WorkflowClientFactory.build.all_workflows_xml(item.pid)
  end
end
