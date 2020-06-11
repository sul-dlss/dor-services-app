# frozen_string_literal: true

# Validates that shelve and publish file attributes are set to false for dark DRO objects.
class ValidateDarkService
  # @param [#dro?] item to be validated
  def initialize(item)
    @item = item
  end

  # @return [Boolean] true if not a DRO (no validation necessary) or if the files have the correct attributes.
  def valid?
    return true unless meets_preconditions?

    invalid_files.empty?
  end

  def invalid_files
    @invalid_files ||= begin
      [].tap do |invalid_files|
        files.each do |file|
          invalid_files << file if file.administrative.shelve || file.access.access != 'dark'
        end
      end
    end
  end

  def invalid_filenames
    invalid_files.map { |invalid_file| invalid_file.filename || invalid_file.label }
  end

  private

  attr_reader :item

  def meets_preconditions?
    item.dro? && item.access&.access == 'dark'
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
