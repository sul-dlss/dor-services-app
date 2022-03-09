# frozen_string_literal: true

module Cocina
  module ToFedora
    # Builds the contentMetadata xml from cocina filesets
    class ContentMetadataGenerator
      # @param [String] druid the identifier of the item
      # @param [Cocina::Models::DROStructural] structural structural metadata in Cocina
      # @param [String] type Cocina object type URI
      # @param [CocinaObjectStore] cocina_object_store
      def self.generate(druid:, structural:, type:, cocina_object_store: CocinaObjectStore)
        new(druid: druid, structural: structural, type: type, cocina_object_store: cocina_object_store).generate
      end

      def initialize(druid:, structural:, type:, cocina_object_store:)
        @druid = druid
        @object_type = type
        @structural = structural
        @cocina_object_store = cocina_object_store
      end

      def generate
        @xml_doc = Nokogiri::XML('<contentMetadata />')
        @xml_doc.root['objectId'] = druid
        @xml_doc.root['type'] = Cocina::ToFedora::ContentType.map(object_type)
        add_book_data
        add_structural_data
        add_members_data
        @xml_doc.to_xml
      end

      private

      attr_reader :object_type, :druid, :structural, :cocina_object_store

      def add_structural_data
        Array(structural&.contains).each_with_index do |cocina_fileset, index|
          # each resource type description gets its own incrementing counter
          resource_type_counters[type_for(cocina_fileset)] += 1
          @xml_doc.root.add_child create_resource_node(cocina_fileset, index + 1)
        end
      end

      def add_book_data
        viewing_direction = structural&.hasMemberOrders&.first&.viewingDirection

        return unless viewing_direction

        direction = viewing_direction == 'right-to-left' ? 'rtl' : 'ltr'
        book_data = Nokogiri::XML::Node.new('bookData', @xml_doc).tap do |node|
          node['readingOrder'] = direction
        end
        @xml_doc.root.add_child(book_data)
      end

      def add_members_data
        members = structural&.hasMemberOrders&.first&.members
        return if members.blank?

        index = 0
        members.each do |external_druid|
          cocina_object = cocina_object_store.find(external_druid)
          Array(cocina_object.structural.contains).each do |cocina_fileset|
            index += 1
            label = cocina_object.description.title.first.value
            @xml_doc.root.add_child create_external_resource_node(cocina_fileset, index, external_druid, label: label)
          end
        end
      end

      def resource_type_counters
        @resource_type_counters ||= Hash.new(0)
      end

      # @param [Hash] cocina_file
      # @return [Nokogiri::XML::Node] the file node
      def create_file_node(cocina_file)
        Nokogiri::XML::Node.new('file', @xml_doc).tap do |file_node|
          file_node['id'] = cocina_file.filename
          file_node['mimetype'] = cocina_file.hasMimeType
          file_node['size'] = cocina_file.size
          file_node['publish'] = publish_attr(cocina_file)
          file_node['shelve'] = shelve_attr(cocina_file)
          file_node['preserve'] = preserve_attr(cocina_file)
          file_node['role'] = cocina_file.use if cocina_file.use
          Array(cocina_file.hasMessageDigests).each do |message_digest|
            file_node.add_child(create_checksum_node(message_digest.type, message_digest.digest))
          end
          file_node.add_child(create_image_data_node(cocina_file.presentation.height, cocina_file.presentation.width)) if cocina_file.presentation
        end
      end

      def publish_attr(cocina_file)
        cocina_file.administrative.publish ? 'yes' : 'no'
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

      def create_image_data_node(height, width)
        Nokogiri::XML::Node.new('imageData', @xml_doc).tap do |image_data_node|
          image_data_node['height'] = height if height
          image_data_node['width'] = width if width
        end
      end

      # @param [Hash] cocina_fileset the cocina fileset
      # @param [Integer] sequence
      def create_resource_node(cocina_fileset, sequence)
        Nokogiri::XML::Node.new('resource', @xml_doc).tap do |resource|
          resource['id'] = IdGenerator.generate_or_existing_fileset_id(resource_id: cocina_fileset.try(:externalIdentifier), druid: druid)
          resource['sequence'] = sequence
          resource['type'] = type_for(cocina_fileset)

          fileset_label = fileset_label(cocina_fileset, resource['type'])
          if fileset_label.present?
            resource.add_child(Nokogiri::XML::Node.new('label', @xml_doc)
              .tap { |c| c.content = fileset_label })
          end
          create_file_nodes(resource, cocina_fileset)
        end
      end

      def create_external_resource_node(cocina_fileset, sequence, external_druid, label:)
        Nokogiri::XML::Node.new('resource', @xml_doc).tap do |resource|
          resource['id'] = IdGenerator.generate_or_existing_fileset_id(resource_id: cocina_fileset.try(:externalIdentifier), druid: druid)
          resource['sequence'] = sequence
          resource['type'] = type_for(cocina_fileset)

          create_external_file_nodes(resource, cocina_fileset, external_druid, label: label)
        end
      end

      def create_external_file_nodes(resource, cocina_fileset, external_druid, label:)
        #   <externalFile fileId="PC0170_s1_B_0540.jp2" mimetype="image/jp2" objectId="druid:tm207xk5096" resourceId="tm207xk5096_1"/>
        #     <relationship objectId="druid:tm207xk5096" type="alsoAvailableAs"/>
        # Note: Only creating if published.
        cocina_fileset.structural.contains.filter { |cocina_file| cocina_file.administrative.publish }.each do |cocina_file|
          resource.add_child(Nokogiri::XML::Node.new('label', @xml_doc).tap { |tag| tag.content = label })
          resource.add_child(create_external_file_node(cocina_file, cocina_fileset.externalIdentifier, external_druid))
          resource.add_child(create_relationship_node(external_druid))
        end
      end

      def create_relationship_node(external_druid)
        Nokogiri::XML::Node.new('relationship', @xml_doc).tap do |relationship|
          relationship['objectId'] = external_druid
          relationship['type'] = 'alsoAvailableAs'
        end
      end

      def create_external_file_node(cocina_file, resource_id, external_druid)
        Nokogiri::XML::Node.new('externalFile', @xml_doc).tap do |file_node|
          file_node['fileId'] = cocina_file.filename
          file_node['mimetype'] = cocina_file.hasMimeType
          file_node['objectId'] = external_druid
          file_node['resourceId'] = resource_id
          # We are guarding for the presence of presentation here, however
          # all "good" external files should be images and have presentation.
          if cocina_file.presentation
            file_node.add_child(create_image_data_node(cocina_file.presentation.height, cocina_file.presentation.width))
          else
            notifier.error('External resource has no presentation data', { external_druid: external_druid })
          end
        end
      end

      def notifier
        @notifier ||= FromFedora::DataErrorNotifier.new(druid: druid)
      end

      def type_for(cocina_fileset)
        cocina_fileset.type.delete_prefix('https://cocina.sul.stanford.edu/models/resources/').delete_suffix('.jsonld')
      end

      def create_file_nodes(resource, cocina_fileset)
        cocina_fileset.structural.contains.each do |cocina_file|
          resource.add_child(create_file_node(cocina_file))
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
