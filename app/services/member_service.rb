# frozen_string_literal: true

# Finds the members of a collection by using Solr
class MemberService
  # @param [String] druid the identifier of the collection
  # @param [Boolean] only_published when true, restrict to only published items
  # @return [Array<Hash<String,String>>] the members of this collection
  def self.for(druid, only_published: false)
    query = "is_member_of_collection_ssim:\"info:fedora/#{druid}\""
    query += ' published_dttsim:[* TO *]' if only_published
    args = {
      fl: 'id,objectType_ssim',
      rows: 100_000_000
    }
    SolrService.query query, args
  end
end
