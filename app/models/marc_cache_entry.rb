# frozen_string_literal: true

# Stores MARC records in a database table
# We use this for indexing (namely for sw_format_ssimdv)
class MarcCacheEntry < ApplicationRecord
  def marc
    @marc ||= MARC::Record.new_from_hash(JSON.parse(marc_data))
  end
end
