# frozen_string_literal: true

# Adds a constituent relationship between a parent work and child works
# by taking the following actions:
#  1. altering the contentMD of the parent
#  2. add isConstituentOf assertions to the RELS-EXT of the children
#  3. saving the parent and the children
class ConstituentService
  VERSION_CLOSE_DESCRIPTION = 'Virtual object created'
  VERSION_CLOSE_SIGNIFICANCE = :major

  # @param [String] parent_druid the identifier of the parent object
  def initialize(parent_druid:)
    @parent_druid = parent_druid
  end

  # This resets the contentMetadataDS of the parent and then adds the child resources.
  # Typically this is only called one time (with a list of all the pids) because
  # subsequent calls will erase the previous changes.
  # @param [Array<String>] child_druids the identifiers of the child objects
  # @raises ActiveFedora::RecordInvalid if AF object validations fail on #save!
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  # @returns [NilClass, Hash] true if successful, hash of errors otherwise (if combinable validation fails)
  def add(child_druids:)
    errors = ItemQueryService.validate_combinable_items(parent: parent_druid, children: child_druids)

    return errors if errors.any?

    # Make sure the parent is open before making modifications
    VersionService.open(parent) unless VersionService.open?(parent)

    reset_metadata!

    child_druids.each do |child_druid|
      add_constituent(child_druid: child_druid)
    end

    # NOTE: parent object is saved as part of closing the version
    VersionService.close(parent, description: VERSION_CLOSE_DESCRIPTION, significance: VERSION_CLOSE_SIGNIFICANCE)

    nil
  end

  private

  attr_reader :parent_druid

  def add_constituent(child_druid:)
    child = ItemQueryService.find_combinable_item(child_druid)
    # Make sure the child is open before making modifications
    VersionService.open(child) unless VersionService.open?(child)

    child.contentMetadata.ng_xml.search('//resource').each do |resource|
      parent.contentMetadata.add_virtual_resource(child.id, resource)
    end

    child.clear_relationship :is_constituent_of
    child.add_relationship :is_constituent_of, parent

    # NOTE: child object is saved as part of closing the version
    VersionService.close(child, description: VERSION_CLOSE_DESCRIPTION, significance: VERSION_CLOSE_SIGNIFICANCE)
  end

  def reset_metadata!
    ResetContentMetadataService.new(item: parent).reset
  end

  def parent
    @parent ||= ItemQueryService.find_combinable_item(parent_druid)
  end
end
