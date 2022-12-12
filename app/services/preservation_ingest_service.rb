# frozen_string_literal: true

require 'moab/stanford'

# Transfers files from the workspace to Preservation (SDR)
#
# NOTE:  this class makes use of data structures from moab-versioning gem,
#  but it does NOT access any preservation storage roots directly
class PreservationIngestService
  # @param [Cocina::Models::DRO, Cocina::Models::Collection] cocina_object The representation of the digital object
  # @return [void] Create the Moab/bag manifests for new version, export data to BagIt bag, kick off the SDR preservation workflow
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def self.transfer(cocina_object)
    druid = cocina_object.externalIdentifier
    workspace = DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root)
    signature_catalog = signature_catalog_from_preservation(druid)
    new_version_id = signature_catalog.version_id + 1
    metadata_dir = PreservationMetadataExtractor.extract(workspace:, cocina_object:)
    verify_version_metadata(metadata_dir, new_version_id)
    version_inventory = Preserve::FileInventoryBuilder.build(metadata_dir:,
                                                             druid:,
                                                             version_id: new_version_id)
    version_additions = signature_catalog.version_additions(version_inventory)
    content_additions = version_additions.group('content')
    if content_additions.nil? || content_additions.files.empty?
      content_dir = nil
    else
      new_file_list = content_additions.path_list
      content_dir = workspace.find_filelist_parent('content', new_file_list)
    end
    content_group = version_inventory.group('content')
    signature_catalog.normalize_group_signatures(content_group, content_dir) unless content_group.nil? || content_group.files.empty?
    # export the bag (in tar format)
    bag_dir = Pathname(Settings.sdr.local_export_home).join(druid.sub('druid:', ''))
    bagger = Moab::Bagger.new(version_inventory, signature_catalog, bag_dir)
    bagger.reset_bag
    bagger.create_bag_inventory(:depositor)
    bagger.deposit_group('content', content_dir)
    bagger.deposit_group('metadata', metadata_dir)
    bagger.create_tagfiles
    Preserve::BagVerifier.verify(directory: bag_dir)
  end
  # NOTE: the following methods should probably all be private

  # @param [String] druid The object identifier
  # @return [Moab::SignatureCatalog] the manifest of all files previously ingested,
  #   or if there is none, a SignatureCatalog object for version 0.
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def self.signature_catalog_from_preservation(druid)
    Preservation::Client.objects.signature_catalog(druid)
  rescue Preservation::Client::NotFoundError
    Moab::SignatureCatalog.new(digital_object_id: druid, version_id: 0)
  end

  # @param [Pathname] metadata_dir the location of the metadata directory in the workspace
  # @param [Integer] expected the version identifer expected to be used in the versionMetadata
  def self.verify_version_metadata(metadata_dir, expected)
    vmfile = metadata_dir.join('versionMetadata.xml')
    verify_version_id(vmfile, expected, vmfile_version_id(vmfile))
    true
  end

  # @param [Pathname] pathname The location of the file containing a version number
  # @param [Integer] expected The version number that should be in the file
  # @param [Integer] found The version number that is actually in the file
  def self.verify_version_id(pathname, expected, found)
    raise "Version mismatch in #{pathname}, expected #{expected}, found #{found}" unless expected == found

    true
  end

  # @param [Pathname] pathname the location of the versionMetadata file
  # @return [Integer] the versionId found in the last version element, or nil if missing
  def self.vmfile_version_id(pathname)
    raise "#{pathname.basename} not found at #{pathname}" unless pathname.exist?

    doc = Nokogiri::XML(File.read(pathname.to_s))
    nodeset = doc.xpath('/versionMetadata/version')
    version_id = nodeset.last['versionId']
    version_id&.to_i
  end
end
