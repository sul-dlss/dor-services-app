# frozen_string_literal: true

# Shows and creates administrative tags. This wraps https://github.com/sul-dlss/dor-services/blob/master/lib/dor/services/tag_service.rb
class AdministrativeTags
  # Retrieve the administrative tags for an item
  #
  # @param item [Dor::Item] the item to list administrative tags for
  # @return [Array<String>] an array of tags (strings), possibly empty
  def self.for(item:)
    item.identityMetadata.ng_xml.search('//tag').map(&:content)
  end

  # Add one or more administrative tags for an item
  #
  # @param item [Dor::Item]  the item to create administrative tag(s) for
  # @param tags [Array<String>] a non-empty array of tags (strings)
  # @return [Array<Nokogiri::XML::Node>]
  def self.create(item:, tags:)
    tags.map { |tag| Dor::TagService.add(item, tag) }
    item.save!
  end
end
