# frozen_string_literal: true

module Cocina
  # Validates that shelve and publish file attributes are set to false for dark DRO objects.
  class ValidateDarkService
    # @param [#dro?] item to be validated
    def initialize(item)
      @item = item
    end

    attr_reader :error

    # @return [Boolean] true if not a DRO (no validation necessary) or if the files have the correct attributes.
    def valid?
      return true unless meets_preconditions?

      @error = "Not all files have dark access and/or are unshelved when item access is dark: #{invalid_filenames}" unless invalid_files.empty?

      @error.nil?
    end

    private

    attr_reader :item

    def meets_preconditions?
      item.dro? && item.access&.access == 'dark'
    end

    def invalid_files
      @invalid_files ||=
        [].tap do |invalid_files|
          files.each do |file|
            invalid_files << file if invalid?(file)
          end
        end
    end

    def invalid_filenames
      invalid_files.map { |invalid_file| invalid_file.filename || invalid_file.label }
    end

    def invalid?(file)
      # Ignore if a WARC
      return false if file.hasMimeType == 'application/warc'

      return true if file.administrative.shelve
      return true if file.access.access != 'dark'

      false
    end

    def files
      [].tap do |files|
        next if item&.structural&.contains.nil?

        item.structural.contains.each do |fileset|
          next if fileset&.structural&.contains.nil?

          fileset.structural.contains.each do |file|
            files << file
          end
        end
      end
    end
  end
end
