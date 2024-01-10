# frozen_string_literal: true

class OrcidBuilder
  # Helper methods for working with Orcid in Cocina
  # NOTE: there is similar code in orcid_client which fetches
  # ORCIDs out of cocina.  Consider consolidating at some point or keeping in sync.
  # see https://github.com/sul-dlss/orcid_client/blob/main/lib/sul_orcid_client/cocina_support.rb
  # and https://github.com/sul-dlss/dor_indexing_app/issues/1022

  # @param [Array<Cocina::Models::Contributor>] contributors
  # @return [String] the list of contributor ORCIDs to index into solr
  def self.build(contributors)
    new(contributors).build
  end

  def initialize(contributors)
    @contributors = Array(contributors)
  end

  def build
    cited_contributors.filter_map { |contributor| orcidid(contributor) }
  end

  private

  attr_reader :contributors

  # @param [Cocina::Models::Contributor] array of contributors
  # @return [Array<String>] array of contributors who are listed as cited
  # Note that non-cited contributors are excluded.
  def cited_contributors
    contributors.select { |contributor| cited?(contributor) }
  end

  # @param [Cocina::Models::Contributor] contributor to check
  # @return [Boolean] true unless the contributor has a citation status of false
  def cited?(contributor)
    contributor.note.none? { |note| note.type == 'citation status' && note.value == 'false' }
  end

  # @param [Cocina::Models::Contributor] contributor to check
  # @return [String, nil] orcid id including host if present
  def orcidid(contributor)
    identifier = contributor.identifier.find { |id| id.type == 'ORCID' }
    return unless identifier

    # some records have the full ORCID URI in the data, just return it if so, e.g. druid:gf852zt8324
    return identifier.uri if identifier.uri
    return identifier.value if identifier.value.start_with?('https://orcid.org/')

    # some records have just the ORCIDID without the URL prefix, add it if so, e.g. druid:tp865ng1792
    return URI.join('https://orcid.org/', identifier.value).to_s if identifier.source.uri.blank?

    URI.join(identifier.source.uri, identifier.value).to_s
  end
end
