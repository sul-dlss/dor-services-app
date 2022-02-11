# frozen_string_literal: true

# Adds a constituent relationship between a virtual_object work and constituent works
# by taking the following actions:
#  1. altering the contentMD of the virtual_object
#  2. add isConstituentOf assertions to the RELS-EXT of the constituents
#  3. saving the virtual_object and the constituents
class ConstituentService
  VERSION_CLOSE_DESCRIPTION = 'Virtual object created'
  VERSION_CLOSE_SIGNIFICANCE = :major

  # @param [String] virtual_object_druid the identifier of the virtual_object object
  def initialize(virtual_object_druid:, event_factory:)
    @virtual_object_druid = virtual_object_druid
    @event_factory = event_factory
  end

  # This resets the contentMetadataDS of the virtual_object and then adds the constituent resources.
  # Typically this is only called one time (with a list of all the pids) because
  # subsequent calls will erase the previous changes.
  # @param [Array<String>] constituent_druids the identifiers of the constituent objects
  # @raise ActiveFedora::RecordInvalid if AF object validations fail on #save!
  # @raise [Preservation::Client::Error] if bad response from preservation catalog.
  # @return [NilClass, Hash] true if successful, hash of errors otherwise (if combinable validation fails)
  def add(constituent_druids:)
    errors = ItemQueryService.validate_combinable_items(virtual_object: virtual_object_druid, constituents: constituent_druids)

    return errors if errors.any?

    # Make sure the virtual_object is open before making modifications
    virtual_object_cocina_object = find_cocina_object(virtual_object_druid)
    VersionService.open(virtual_object_cocina_object, event_factory: event_factory) unless VersionService.open?(virtual_object_cocina_object)

    virtual_object_fedora_object = find_fedora_object(virtual_object_druid)
    reset_metadata!(virtual_object_fedora_object)

    constituent_druids.each do |constituent_druid|
      add_constituent(constituent_druid: constituent_druid, virtual_object: virtual_object_fedora_object)
    end
    virtual_object_fedora_object.save!

    VersionService.close(find_cocina_object(virtual_object_druid),
                         {
                           description: VERSION_CLOSE_DESCRIPTION,
                           significance: VERSION_CLOSE_SIGNIFICANCE
                         },
                         event_factory: event_factory)

    nil
  end

  private

  attr_reader :virtual_object_druid, :event_factory

  def add_constituent(constituent_druid:, virtual_object:)
    constituent_cocina_object = find_cocina_object(constituent_druid)
    # Make sure the constituent is open before making modifications
    VersionService.open(constituent_cocina_object, event_factory: event_factory) unless VersionService.open?(constituent_cocina_object)

    constituent = find_fedora_object(constituent_druid)
    constituent.contentMetadata.ng_xml.search('//resource').each do |resource|
      virtual_object.contentMetadata.add_virtual_resource(constituent.id, resource)
    end

    constituent.clear_relationship :is_constituent_of
    constituent.add_relationship :is_constituent_of, virtual_object

    constituent.save!

    constituent_cocina_object = find_cocina_object(constituent_druid)
    VersionService.close(constituent_cocina_object,
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
