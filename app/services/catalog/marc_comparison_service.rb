# frozen_string_literal: true

module Catalog
  # service for comparing MARC retrieved from Symphony vs MARC retrieved from Folio
  # This class is not permanent - it is only useful for preparing for the Folio migration.  Therefore, it does not have thorough specs.
  class MarcComparisonService
    def initialize(sort_field_list_before_comparing: false)
      @sort_field_list_before_comparing = sort_field_list_before_comparing
    end

    def diff_marc_for_catkey_list(symphony_catkey_list:)
      { successful_comparisons: [], failed_comparisons: [] }.tap do |h|
        symphony_catkey_list.each do |symphony_catkey|
          diff_marc_for_catkey(symphony_catkey:).tap do |diff_result|
            if diff_result[:marc_hash_diff].present? && !diff_result[:marc_hash_diff].is_a?(StandardError)
              h[:successful_comparisons] << { symphony_catkey => diff_result[:marc_hash_diff] }
            else
              h[:failed_comparisons] << { symphony_catkey => diff_result.slice(:symphony_marc, :folio_marc) }
            end
          end
        end
      end
    end

    # Given a Symphony catkey, this method attempts to retrieve the MARC for it from
    # both Symphony and Folio.  If it successfully gets a MARC::Record from each system,
    # it attempts to diff the Hash representations.  It tries to return a Hash with the
    # MARC::Record representation of the MARC from each system, and an Array result from
    # Hashdiff representing the differences detected between the MARC in each system.
    #
    # If any of those operations errors unexpectedly, the result field is set to the exception
    # that was thrown, instead of the MARC::Record or Array object.
    #
    # @return [Hash] as possible for a given symphony ckey: MARC::Record from each of Symphony and
    #  Folio, and a diff of the hash representation for each; or, a nil diff and an exception for
    #  one or both MARC::Record retrievals; or an exception for the diff and a MARC::Record from each
    #  of Symphony and Folio
    def diff_marc_for_catkey(symphony_catkey:)
      error_message_list = []

      symphony_marc = begin
        SymphonyReader.new(catkey: symphony_catkey).to_marc
      rescue StandardError => e
        error_message_list << 'Error retrieving Symphony MARC'
        e
      end

      folio_marc = begin
        FolioReader.new(folio_instance_hrid: "a#{symphony_catkey}").to_marc
      rescue StandardError => e
        error_message_list << 'Error retrieving Folio MARC'
        e
      end

      marc_hash_diff = begin
        # defaults to nil if condition isn't met
        diff_marc_hashes(symphony_marc.to_hash, folio_marc.to_hash) if symphony_marc.is_a?(MARC::Record) && folio_marc.is_a?(MARC::Record)
      rescue StandardError => e
        error_message_list << "Error diffing Symphony and Folio MARC: #{e}"
        e
      end

      Rails.logger.warn("Error(s) diffing MARC for #{symphony_catkey}: #{error_message_list}") if error_message_list.present?

      { symphony_marc:, folio_marc:, marc_hash_diff: }
    end

    private

    def sort_marc_hash_field_list!(marc_hash)
      multi_keyed_hash = marc_hash['fields'].find { |marc_field_hash| marc_field_hash.keys.size > 1 }
      raise "Expected one key per MARC field hash, but #{multi_keyed_hash} has #{multi_keyed_hash.keys.size}" if multi_keyed_hash

      marc_hash['fields'].sort_by! { |marc_field_hash| marc_field_hash.keys.first }
    end

    def diff_marc_hashes(left_hash, right_hash)
      if sort_field_list_before_comparing?
        sort_marc_hash_field_list!(left_hash)
        sort_marc_hash_field_list!(right_hash)
      end

      # "you can pass a custom value for :similarity instead of the default 0.8. This is interpreted as a ratio of
      # similarity (default is 80% similar, whereas :similarity => 0.5 would look for at least a 50% similarity)."
      # Arcadia says fine to strip whitespace for comparison, because MARC to MODS XSLT does the same.
      Hashdiff.diff(left_hash, right_hash, strip: true, similarity: 0.6)
    end

    def sort_field_list_before_comparing?
      @sort_field_list_before_comparing
    end
  end
end
