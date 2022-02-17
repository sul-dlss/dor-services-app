# frozen_string_literal: true

module Publish
  # Creates the descriptive XML that we display on purl.stanford.edu
  class PublicDescMetadataService
    attr_reader :cocina_object

    MODS_NS = 'http://www.loc.gov/mods/v3'

    def initialize(cocina_object)
      @cocina_object = cocina_object
    end

    # @return [Nokogiri::XML::Document] A copy of the descriptiveMetadata of the object, to be modified
    def doc
      @doc ||= Cocina::ToFedora::Descriptive.transform(cocina_object.description, cocina_object.externalIdentifier)
    end

    # @return [String] Public descriptive medatada XML
    def to_xml(include_access_conditions: true, prefixes: nil, template: nil)
      ng_xml(include_access_conditions: include_access_conditions).to_xml
    end

    # @return [Nokogiri::XML::Document]
    def ng_xml(include_access_conditions: true)
      @ng_xml ||= begin
        add_collection_reference!
        AccessConditions.add(public_mods: doc, access: cocina_object.access) if include_access_conditions
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

    # Export DOI into the public descMetadata to allow PURL to display it
    def add_doi
      return unless cocina_object.dro? && cocina_object.identification.doi

      identifier = doc.create_element('identifier', xmlns: MODS_NS)
      identifier.content = "https://doi.org/#{cocina_object.identification.doi}"
      identifier['type'] = 'doi'
      identifier['displayLabel'] = 'DOI'
      doc.root << identifier
    end

    # expand constituent relations into relatedItem references -- see JUMBO-18
    # @return [Void]
    def add_constituent_relations!
      find_virtual_object.each do |solr_doc|
        # create the MODS relation
        relatedItem = doc.create_element('relatedItem', xmlns: MODS_NS)
        relatedItem['type'] = 'host'
        relatedItem['displayLabel'] = 'Appears in'

        # load the title from the virtual object's DC.title
        titleInfo = doc.create_element('titleInfo', xmlns: MODS_NS)
        title = doc.create_element('title', xmlns: MODS_NS)
        title.content = solr_doc.fetch(:title)
        titleInfo << title
        relatedItem << titleInfo

        # point to the PURL for the virtual object
        location = doc.create_element('location', xmlns: MODS_NS)
        url = doc.create_element('url', xmlns: MODS_NS)
        url.content = purl_url(solr_doc.fetch(:id))
        location << url
        relatedItem << location

        # finish up by adding relation to public MODS
        doc.root << relatedItem
      end
    end

    # @return[Array<Dor::Item>]
    def find_virtual_object
      query = "has_constituents_ssim:#{cocina_object.externalIdentifier.sub(':', '\:')}"
      response = solr_conn.get('select', params: { q: query, fl: 'id sw_display_title_tesim' })
      response.fetch('response').fetch('docs').map do |row|
        { id: row.fetch('id'), title: row.fetch('sw_display_title_tesim').first }
      end
    end

    def solr_conn
      ActiveFedora::SolrService.instance.conn
    end

    def purl_url(druid)
      "https://#{Settings.stacks.document_cache_host}/#{druid.delete_prefix('druid:')}"
    end

    # Adds to desc metadata a relatedItem with information about the collection this object belongs to.
    # For use in published mods and mods-to-DC conversion.
    # @return [Void]
    def add_collection_reference!
      return if cocina_object.collection? || cocina_object.structural&.isMemberOf.blank?

      collections = CocinaObjectStore.find_collections_for(cocina_object, swallow_exceptions: true)

      remove_related_item_nodes_for_collections!

      collections.each do |cocina_collection|
        add_related_item_node_for_collection! cocina_collection
      end
    end

    # Remove existing relatedItem entries for collections from descMetadata
    def remove_related_item_nodes_for_collections!
      doc.search('/mods:mods/mods:relatedItem[@type="host"]/mods:typeOfResource[@collection=\'yes\']', 'mods' => 'http://www.loc.gov/mods/v3').each do |node|
        node.parent.remove
      end
    end

    def add_related_item_node_for_collection!(cocina_collection)
      title_node         = Nokogiri::XML::Node.new('title', doc)
      title_node.content = TitleBuilder.build(cocina_collection.description.title)

      title_info_node = Nokogiri::XML::Node.new('titleInfo', doc)
      title_info_node.add_child(title_node)

      # e.g.:
      #   <location>
      #     <url>http://purl.stanford.edu/rh056sr3313</url>
      #   </location>
      loc_node = doc.create_element('location', xmlns: MODS_NS)
      url_node = doc.create_element('url', xmlns: MODS_NS)
      url_node.content = purl_url(cocina_collection.externalIdentifier)
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
