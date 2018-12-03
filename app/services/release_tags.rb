# frozen_string_literal: true

# Creates workspaces.  This replaces https://github.com/sul-dlss/dor-services/blob/master/lib/dor/models/concerns/assembleable.rb
class ReleaseTags
  # Add a release node for the item
  # Will use the current time if timestamp not supplied. You can supply a timestap for correcting history, etc if desired
  # Timestamp will be calculated by the function
  #
  # @param work [Dor::Item]  the work to create the release tag for
  # @param [Hash] params all the other stuff
  # @option params [Boolean] release: True or false for the release node
  # @return [Nokogiri::XML::Element] the tag added if successful
  # @raise [ArgumentError] Raised if attributes are improperly supplied
  #
  # @example
  #  ReleaseTags.create(item, release: true, what: 'self', to: 'Searchworks', who: 'petucket'})
  def self.create(work, attrs)
    release = attrs.delete(:release)
    attrs[:when] ||= Time.now.utc.iso8601 # add the timestamp
    validate_release_attributes(release, attrs)
    work.identityMetadata.add_value(:release, release.to_s, attrs)
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
