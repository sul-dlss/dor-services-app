# frozen_string_literal: true

module Cocina
  # This replaces the :link: placeholder in the citation with the purl, which we are now able to derive.
  # This is specifically for H2, but could be utilized by any client that provides preferred citation.
  # This action has to happen regardless of how we persist the data.
  class AddPurlToDescription
    def self.call(description, pid)
      return description unless description.note

      notes = description.note.map do |note|
        if note.type == 'preferred citation'
          note.new(value: note.value.gsub(/:link:/, purl_link(pid)))
        else
          note
        end
      end
      description.new(note: notes)
    end

    def self.purl_link(pid)
      "#{Settings.release.purl_base_url}/#{pid.delete_prefix('druid:')}"
    end
    private_class_method :purl_link
  end
end
