# frozen_string_literal: true

# Shows and creates release tags. This replaces parts of https://github.com/sul-dlss/dor-services/blob/main/lib/dor/models/concerns/releaseable.rb
class ReleaseTags
  # Retrieve the release tags for an item and all the collections that it is a part of
  #
  # @param dro_object [Cocina::DRO] the DRO to list release tags for
  # @return [Hash] (see Dor::ReleaseTags::IdentityMetadata.released_for)
  def self.for(dro_object:)
    IdentityMetadata.for(dro_object).released_for({})
  end

  # Determine if the supplied tag is a valid release node that meets all requirements
  #
  # @param tag [Boolean] True or false for the release node
  # @param attrs [hash] A hash of attributes for the tag, must contain :when, a ISO 8601 timestamp and :who to identify who or what added the tag, :to,
  # @raise [ArgumentError]  Raises an error of the first fault in the release tag
  # @return [Boolean] Returns true if no errors found
  def self.validate_release_attributes(tag, attrs = {})
    raise ArgumentError, ':when is not iso8601' if attrs[:when].match('\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z').nil?

    [:who, :to, :what].each do |check_attr|
      next unless attrs[check_attr]
      raise ArgumentError, "#{check_attr} not supplied as a String" unless attrs[check_attr].is_a? String
    end
    raise ArgumentError, ':what must be self or collection' unless %w[self collection].include? attrs[:what]
    raise ArgumentError, 'the value set for this tag is not a boolean' unless [true, false].include? tag
  end
  private_class_method :validate_release_attributes
end
