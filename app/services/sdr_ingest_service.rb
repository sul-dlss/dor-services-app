# frozen_string_literal: true

require 'moab/stanford'

# Transfers files from the workspace to Preservation (SDR)
#
# NOTE:  this class makes use of data structures from moab-versioning gem,
#  but it does NOT access any preservation storage roots directly
class SdrIngestService
  # @param [Dor::Item] dor_item The representation of the digital object
  # @return [void] Create the Moab/bag manifests for new version, export data to BagIt bag, kick off the SDR preservation workflow
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  def self.transfer(dor_item)
    druid = dor_item.pid
    workspace = DruidTools::Druid.new(druid, Settings.sdr.local_workspace_root)
    signature_catalog = signature_catalog_from_preservation(druid)
    new_version_id = signature_catalog.version_id + 1
    metadata_dir = DatastreamExtractor.extract_datastreams(item: dor_item, workspace: workspace)
    verify_version_metadata(metadata_dir, new_version_id)
    version_inventory = get_version_inventory(metadata_dir, druid, new_version_id)
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
    verify_bag_structure(bag_dir)
  end

  # Note: the following methods should probably all be private

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
    verify_pathname(pathname)
    doc = Nokogiri::XML(File.read(pathname.to_s))
    nodeset = doc.xpath('/versionMetadata/version')
    version_id = nodeset.last['versionId']
    version_id.nil? ? nil : version_id.to_i
  end

  # @param [Pathname] metadata_dir The location of the the object's metadata files
  # @param [String] druid The object identifier
  # @param [Integer] version_id The version number
  # @return [Moab::FileInventory] Generate and return a version inventory for the object
  def self.get_version_inventory(metadata_dir, druid, version_id)
    version_inventory = get_content_inventory(metadata_dir, druid, version_id)
    version_inventory.groups << get_metadata_file_group(metadata_dir)
    version_inventory
  end

  # @param [Pathname] metadata_dir The location of the the object's metadata files
  # @param [String] druid The object identifier
  # @param [Integer] version_id The version number
  # @return [Moab::FileInventory] Parse the contentMetadata
  #   and generate a new version inventory object containing a content group
  def self.get_content_inventory(metadata_dir, druid, version_id)
    content_metadata = get_content_metadata(metadata_dir)
    if content_metadata
      Stanford::ContentInventory.new.inventory_from_cm(content_metadata, druid, 'preserve', version_id)
    else
      Moab::FileInventory.new(type: 'version', digital_object_id: druid, version_id: version_id)
    end
  end

  # @param [Pathname] metadata_dir The location of the the object's metadata files
  # @return [String] Return the contents of the contentMetadata.xml file from the content directory
  def self.get_content_metadata(metadata_dir)
    content_metadata_pathname = metadata_dir.join('contentMetadata.xml')
    content_metadata_pathname.read if content_metadata_pathname.exist?
  end

  # @param [Pathname] metadata_dir The location of the the object's metadata files
  # @return [Moab::FileGroup] Traverse the metadata directory and generate a metadata group
  def self.get_metadata_file_group(metadata_dir)
    file_group = Moab::FileGroup.new(group_id: 'metadata').group_from_directory(metadata_dir)
    file_group
  end

  # @param [Pathname] bag_dir the location of the bag to be verified
  # @return [Boolean] true if all required files exist, raises exception if not
  def self.verify_bag_structure(bag_dir)
    verify_pathname(bag_dir)
    verify_pathname(bag_dir.join('data'))
    verify_pathname(bag_dir.join('bagit.txt'))
    verify_pathname(bag_dir.join('bag-info.txt'))
    verify_pathname(bag_dir.join('manifest-sha256.txt'))
    verify_pathname(bag_dir.join('tagmanifest-sha256.txt'))
    verify_pathname(bag_dir.join('versionAdditions.xml'))
    verify_pathname(bag_dir.join('versionInventory.xml'))
    verify_pathname(bag_dir.join('data', 'metadata', 'versionMetadata.xml'))
    true
  end

  # @param [Pathname] pathname The file whose existence should be verified
  # @return [Boolean] true if file exists, raises exception if not
  def self.verify_pathname(pathname)
    raise "#{pathname.basename} not found at #{pathname}" unless pathname.exist?

    true
  end
end
