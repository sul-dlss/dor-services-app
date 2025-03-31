# frozen_string_literal: true

# Determines access by merging provided access with default access.
class AccessMergeService
  # @param [Cocina::Models::RequestDRO,Cocina::Models::RequestCollection] cocina_object for which to determine access.
  # @param [Cocina::Models::AdminPolicy] apo_object admin policy for the cocina_object
  # @return [Cocina::Models::DROAccess]
  def self.merge(cocina_object, apo_object)
    new(cocina_object, apo_object).merge
  end

  def initialize(cocina_object, apo_object)
    @cocina_object = cocina_object
    @apo_object = apo_object
  end

  def merge # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity
    # Admin policy may not have default access.
    if default_access.nil?
      # access is optional on a request, so may be nil.
      return cocina_object.access || access_class.new
    end

    props = cocina_object.access.to_h || {}

    # Note for below: For cocina, an omitted value will not have a key in the hash.

    # Add rights (access, cdl, download, location) if not present.
    props.merge!(rights) unless props.key?(:view)

    # Add others
    props[:copyright] = default_access.copyright unless props.key?(:copyright)
    unless props.key?(:useAndReproductionStatement)
      props[:useAndReproductionStatement] =
        default_access.useAndReproductionStatement
    end
    props[:license] = default_access.license unless props.key?(:license)

    access_class.new(props.compact)
  end

  private

  attr_reader :cocina_object, :apo_object

  def default_access
    @default_access ||= apo_object.administrative.accessTemplate
  end

  def rights
    cocina_object.collection? ? collection_rights : dro_rights
  end

  def collection_rights
    {
      view: default_access.view == 'dark' ? 'dark' : 'world'
    }
  end

  def dro_rights
    default_access.to_h.slice(:view, :controlledDigitalLending, :download, :location)
  end

  def access_class
    cocina_object.collection? ? Cocina::Models::CollectionAccess : Cocina::Models::DROAccess
  end
end
