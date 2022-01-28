# frozen_string_literal: true

# Responsible for finding a path to a thumbnail based on the contentMetadata of an object
class ThumbnailService
  # allow the mimetype attribute to be lower or camelcase when searching to make it more robust
  MIME_TYPE = 'image/jp2'

  # @param [Cocina::Model::DRO] object
  def initialize(object)
    @object = object
  end

  attr_reader :object

  # @return [String] the computed thumb filename, with the druid prefix and a slash in front of it, e.g. oo000oo0001/filenamewith space.jp2
  def thumb
    return unless object.respond_to?(:structural) && object.structural.present?

    object.structural.contains.each do |file_set|
      file_set.structural.contains.each do |file|
        next unless file.hasMimeType.include?(MIME_TYPE)

        return "#{Dor::PidUtils.remove_druid_prefix(object.externalIdentifier)}/#{file.filename}"
      end
    end

    return if object.structural.hasMemberOrders.empty?

    object.structural.hasMemberOrders.first.members.first
  end
end
