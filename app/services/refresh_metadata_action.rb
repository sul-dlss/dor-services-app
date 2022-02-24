# frozen_string_literal: true

# Look into identityMetadata for compliant ids and use them to fetch
# descriptive metadata from Symphony.  Put the fetched value in the descriptive object.
class RefreshMetadataAction
  # @return [NilClass,Object] returns nil if there was no resolvable metadata id.
  # @raises SymphonyReader::ResponseError
  def self.run(identifiers:, pid:)
    new(identifiers: identifiers, pid: pid).run
  end

  # @param [Array<String>] identifiers the set of identifiers that might be resolvable (e.g. ["catkey:123"])
  # @param [String] pid
  def initialize(identifiers:, pid:)
    @identifiers = identifiers
    @pid = pid
  end

  # Returns nil if it didn't retrieve anything
  # @raises SymphonyReader::ResponseError
  def run
    content = fetch_mods
    return nil if content.nil?

    Cocina::FromFedora::Descriptive.props(mods: Nokogiri::XML(content), druid: pid)
  end

  private

  attr_reader :identifiers, :pid

  # @raises SymphonyReader::ResponseError
  def fetch_mods
    metadata_id = MetadataService.resolvable(identifiers).first
    metadata_id.nil? ? nil : MetadataService.fetch(metadata_id.to_s)
  end
end
