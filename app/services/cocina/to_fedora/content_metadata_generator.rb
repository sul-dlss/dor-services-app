# frozen_string_literal: true

module Cocina
  module ToFedora
    # Builds the contentMetadata xml from cocina filesets
    class ContentMetadataGenerator
      # @param [String] druid the identifier of the item
      # @param [Cocina::Model::RequestDRO] object the cocina model
      def self.generate(druid:, object:)
        new(druid: druid, object: object).generate
      end

      def initialize(druid:, object:)
        @druid = druid
        @object_type = object.type
        # NOTE: structural is an optional element, so we need to guard for nil.
        @resources = object.structural&.contains || []
        @orders = object.structural&.hasMemberOrders
      end

      def generate
        @xml_doc = Nokogiri::XML('<contentMetadata />')
        @xml_doc.root['objectId'] = druid
        @xml_doc.root['type'] = Cocina::ToFedora::ContentType.map(object_type)
        add_book_data(orders.first) if orders.present?
        resources.each_with_index do |cocina_fileset, index|
          # each resource type description gets its own incrementing counter
          type = ResourceType.for(object_type: object_type, file_set: cocina_fileset)
          resource_type_counters[type] += 1
          @xml_doc.root.add_child create_resource_node(cocina_fileset, type, index + 1)
        end

        @xml_doc.to_xml
      end

      private

      attr_reader :object_type, :resources, :druid, :orders

      def add_book_data(sequence)
        direction = sequence.viewingDirection == 'right-to-left' ? 'rtl' : 'ltr'
        book_data = Nokogiri::XML::Node.new('bookData', @xml_doc).tap do |node|
          node['readingOrder'] = direction
        end
        @xml_doc.root.add_child(book_data)
      end

      def resource_type_counters
        @resource_type_counters ||= Hash.new(0)
      end

      # @param [String] id
      # @param [Hash] cocina_file
      # @return [Nokogiri::XML::Node] the file node
      def create_file_node(id, cocina_file)
        Nokogiri::XML::Node.new('file', @xml_doc).tap do |file_node|
          file_node['id'] = id
          file_node['mimetype'] = cocina_file.hasMimeType
          file_node['size'] = cocina_file.size
          file_node['publish'] = publish_attr(cocina_file)
          file_node['shelve'] = shelve_attr(cocina_file)
          file_node['preserve'] = preserve_attr(cocina_file)
          file_node['role'] = cocina_file.use if cocina_file.use
          Array(cocina_file.hasMessageDigests).each do |message_digest|
            file_node.add_child(create_checksum_node(message_digest.type, message_digest.digest))
          end
          file_node.add_child("\n      <imageData height=\"#{cocina_file.presentation.height}\" width=\"#{cocina_file.presentation.width}\" />\n") if cocina_file.presentation
        end
      end

      def publish_attr(cocina_file)
        cocina_file.access.access == 'dark' ? 'no' : 'yes'
      end

      def shelve_attr(cocina_file)
        cocina_file.administrative.shelve ? 'yes' : 'no'
      end

      def preserve_attr(cocina_file)
        cocina_file.administrative.sdrPreserve ? 'yes' : 'no'
      end

      def create_checksum_node(algorithm, digest)
        Nokogiri::XML::Node.new('checksum', @xml_doc).tap do |checksum_node|
          checksum_node['type'] = algorithm
          checksum_node.content = digest
        end
      end

      # @param [Hash] cocina_fileset the cocina fileset
      # @param [String] type resource type to use
      # @param [Integer] sequence
      def create_resource_node(cocina_fileset, type, sequence)
        pid = druid.gsub('druid:', '') # remove druid prefix when creating IDs

        Nokogiri::XML::Node.new('resource', @xml_doc).tap do |resource|
          resource['id'] = "#{pid}_#{sequence}"
          resource['sequence'] = sequence
          resource['type'] = type

          resource.add_child(Nokogiri::XML::Node.new('label', @xml_doc)
            .tap { |c| c.content = fileset_label(cocina_fileset, resource['type']) })
          create_file_nodes(resource, cocina_fileset)
        end
      end

      def create_file_nodes(resource, cocina_fileset)
        cocina_fileset.structural.contains.each do |cocina_file|
          resource.add_child(create_file_node(cocina_file.filename, cocina_file))
        end
      end

      def fileset_label(cocina_fileset, resource_type)
        # but if one of the files has a label, use it instead
        cocina_fileset.label || "#{resource_type.capitalize} #{resource_type_counters[resource_type]}"
      end

      # @return [Hash<String,Assembly::ObjectFile>]
      def object_files
        @object_files ||= file_names.transform_values do |file_path|
          Assembly::ObjectFile.new(file_path)
        end
      end
    end
  end
end
