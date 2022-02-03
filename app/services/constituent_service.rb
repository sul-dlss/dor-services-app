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
  def initialize(parent_druid:, event_factory:)
    @parent_druid = parent_druid
    @event_factory = event_factory
  end

  # This resets the contentMetadataDS of the parent and then adds the child resources.
  # Typically this is only called one time (with a list of all the pids) because
  # subsequent calls will erase the previous changes.
  # @param [Array<String>] child_druids the identifiers of the child objects
  # @raise ActiveFedora::RecordInvalid if AF object validations fail on #save!
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  # @return [NilClass, Hash] true if successful, hash of errors otherwise (if combinable validation fails)
  def add(child_druids:)
    errors = ItemQueryService.validate_combinable_items(parent: parent_druid, children: child_druids)

    return errors if errors.any?

    # Make sure the parent is open before making modifications
    parent_cocina_object = find_cocina_object(parent_druid)
    VersionService.open(parent_cocina_object, event_factory: event_factory) unless VersionService.open?(parent_cocina_object)

    parent_fedora_object = find_fedora_object(parent_druid)
    reset_metadata!(parent_fedora_object)

    child_druids.each do |child_druid|
      add_constituent(child_druid: child_druid, parent: parent_fedora_object)
    end
    parent_fedora_object.save!

    VersionService.close(find_cocina_object(parent_druid),
                         {
                           description: VERSION_CLOSE_DESCRIPTION,
                           significance: VERSION_CLOSE_SIGNIFICANCE
                         },
                         event_factory: event_factory)

    nil
  end

  private

  attr_reader :parent_druid, :event_factory

  def add_constituent(child_druid:, parent:)
    child_cocina_object = find_cocina_object(child_druid)
    # Make sure the child is open before making modifications
    VersionService.open(child_cocina_object, event_factory: event_factory) unless VersionService.open?(child_cocina_object)

    child = find_fedora_object(child_druid)
    child.contentMetadata.ng_xml.search('//resource').each do |resource|
      parent.contentMetadata.add_virtual_resource(child.id, resource)
    end

    child.clear_relationship :is_constituent_of
    child.add_relationship :is_constituent_of, parent

    child.save!

    child_cocina_object = find_cocina_object(child_druid)
    VersionService.close(child_cocina_object,
                         {
                           description: VERSION_CLOSE_DESCRIPTION,
                           significance: VERSION_CLOSE_SIGNIFICANCE
                         },
                         event_factory: event_factory)
  end

  def reset_metadata!(fedora_object)
    ResetContentMetadataService.new(item: fedora_object).reset
  end

  def find_fedora_object(druid)
    ItemQueryService.find_combinable_item(druid)
  end

  def find_cocina_object(druid)
    Cocina::Mapper.build(find_fedora_object(druid))
  end
end
