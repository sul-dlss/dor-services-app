# frozen_string_literal: true

module Publish
  # Creates the descriptive XML that we display on purl.stanford.edu
  class PublicDescMetadataService
    attr_reader :object

    NOKOGIRI_DEEP_COPY = 1
    MODS_NS = 'http://www.loc.gov/mods/v3'

    def initialize(object)
      @object = object
    end

    # @return [Nokogiri::XML::Document] A copy of the descriptiveMetadata of the object, to be modified
    def doc
      @doc ||= object.descMetadata.ng_xml.dup(NOKOGIRI_DEEP_COPY)
    end

    # @return [String] Public descriptive medatada XML
    def to_xml(include_access_conditions: true, prefixes: nil, template: nil)
      ng_xml(include_access_conditions: include_access_conditions).to_xml
    end

    # @return [Nokogiri::XML::Document]
    def ng_xml(include_access_conditions: true)
      @ng_xml ||= begin
        add_collection_reference!
        AccessConditions.add(public_mods: doc, rights_md: object.rightsMetadata) if include_access_conditions
        add_constituent_relations!
        add_doi
        strip_comments!

        new_doc = Nokogiri::XML(doc.to_xml, &:noblanks)
        new_doc.encoding = 'UTF-8'
        new_doc
      end
    end

    private

    def strip_comments!
      doc.xpath('//comment()').remove
    end

    # We began to record DOI names in identityMetadata in the Summer of 2021
    # So we need to export this into the public descMetadata in order to allow
    # PURL to display the DOI
    def add_doi
      value = object.identityMetadata.ng_xml.xpath('//doi').first
      return unless value

      identifier = doc.create_element('identifier', xmlns: MODS_NS)
      identifier.content = "https://doi.org/#{value.text}"
      identifier['type'] = 'doi'
      identifier['displayLabel'] = 'DOI'
      doc.root << identifier
    end

    # expand constituent relations into relatedItem references -- see JUMBO-18
    # @return [Void]
    def add_constituent_relations!
      object.relationships(:is_constituent_of).each do |parent|
        # fetch the parent object to get title
        druid = parent.gsub(%r{^info:fedora/}, '')
        parent_item = Dor.find(druid)

        # create the MODS relation
        relatedItem = doc.create_element('relatedItem', xmlns: MODS_NS)
        relatedItem['type'] = 'host'
        relatedItem['displayLabel'] = 'Appears in'

        # load the title from the parent's DC.title
        titleInfo = doc.create_element('titleInfo', xmlns: MODS_NS)
        title = doc.create_element('title', xmlns: MODS_NS)
        title.content = parent_item.full_title
        titleInfo << title
        relatedItem << titleInfo

        # point to the PURL for the parent
        location = doc.create_element('location', xmlns: MODS_NS)
        url = doc.create_element('url', xmlns: MODS_NS)
        url.content = "http://#{Settings.stacks.document_cache_host}/#{druid.split(':').last}"
        location << url
        relatedItem << location

        # finish up by adding relation to public MODS
        doc.root << relatedItem
      end
    end

    # Adds to desc metadata a relatedItem with information about the collection this object belongs to.
    # For use in published mods and mods-to-DC conversion.
    # @return [Void]
    def add_collection_reference!
      collections = object.relationships(:is_member_of_collection)
      return if collections.empty?

      remove_related_item_nodes_for_collections!

      collections.each do |collection_uri|
        collection_druid = collection_uri.gsub('info:fedora/', '')
        add_related_item_node_for_collection! collection_druid
      end
    end

    # Remove existing relatedItem entries for collections from descMetadata
    def remove_related_item_nodes_for_collections!
      doc.search('/mods:mods/mods:relatedItem[@type="host"]/mods:typeOfResource[@collection=\'yes\']', 'mods' => 'http://www.loc.gov/mods/v3').each do |node|
        node.parent.remove
      end
    end

    def add_related_item_node_for_collection!(collection_druid)
      begin
        collection_obj = Dor.find(collection_druid)
      rescue ActiveFedora::ObjectNotFoundError
        return nil
      end

      title_node         = Nokogiri::XML::Node.new('title', doc)
      title_node.content = collection_obj.full_title

      title_info_node = Nokogiri::XML::Node.new('titleInfo', doc)
      title_info_node.add_child(title_node)

      # e.g.:
      #   <location>
      #     <url>http://purl.stanford.edu/rh056sr3313</url>
      #   </location>
      loc_node = doc.create_element('location', xmlns: MODS_NS)
      url_node = doc.create_element('url', xmlns: MODS_NS)
      url_node.content = "https://#{Settings.stacks.document_cache_host}/#{collection_druid.split(':').last}"
      loc_node << url_node

      type_node = doc.create_element('typeOfResource', xmlns: MODS_NS)
      type_node['collection'] = 'yes'

      related_item_node = doc.create_element('relatedItem', xmlns: MODS_NS)
      related_item_node['type'] = 'host'

      related_item_node.add_child(title_info_node)
      related_item_node.add_child(loc_node)
      related_item_node.add_child(type_node)

      doc.root.add_child(related_item_node)
    end
  end
end
