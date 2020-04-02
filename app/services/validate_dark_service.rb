# frozen_string_literal: true

# Validates that shelve and publish file attributes are set to false for dark objects.
class ValidateDarkService
  # @param [Cocina::Models::DRO,Cocina::Models::RequestDRO] item to be validated
  def initialize(item)
    @item = item
  end

  def valid?
    invalid_files.empty?
  end

  def invalid_files
    @invalid_files ||= begin
      [].tap do |invalid_files|
        next unless item.access&.access == 'dark'

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
