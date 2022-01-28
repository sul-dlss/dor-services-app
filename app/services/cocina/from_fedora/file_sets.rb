# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the FileSet instance from a Dor::Item
    class FileSets
      def self.build(content_metadata_ds, rights_metadata:, version:, notifier:, ignore_resource_type_errors: false)
        new(
          content_metadata_ds,
          rights_metadata: rights_metadata,
          version: version,
          notifier: notifier,
          ignore_resource_type_errors: ignore_resource_type_errors
        ).build
      end

      def initialize(content_metadata_ds, rights_metadata:, version:, notifier:, ignore_resource_type_errors:)
        @content_metadata_ds = content_metadata_ds
        @rights_metadata = rights_metadata
        @version = version
        @ignore_resource_type_errors = ignore_resource_type_errors
        @notifier = notifier
      end

      def build
        content_metadata_ds.ng_xml.xpath('//resource[file]').map do |resource_node|
          files = build_files(resource_node.xpath('file'))
          structural = {}
          structural[:contains] = files if files.present?
          {
            externalIdentifier: IdGenerator.generate_or_existing_fileset_id(resource_node['id']),
            type: resource_type(resource_node),
            version: version,
            structural: structural
          }.tap do |attrs|
            attrs[:label] = resource_node.xpath('label', 'attr[@type="label"]').text # some will be missing labels, they will just be blank
          end
        end
      end

      private

      attr_reader :content_metadata_ds, :rights_metadata, :version, :notifier, :ignore_resource_type_errors

      def rights_object
        rights_metadata.dra_object
      end

      def resource_type(resource_node)
        val = resource_node['type']&.underscore
        val = 'three_dimensional' if val == '3d'
        if val && Cocina::Models::Vocab::Resources.respond_to?(val)
          Cocina::Models::Vocab::Resources.public_send(val)
        else
          # skip sending alerts for Project Phoenix (old Google books) which are known to have bad resource types
          notifier.error("Invalid resource type: '#{val}'") unless ignore_resource_type_errors
          Cocina::Models::Vocab::Resources.file
        end
      end

      def digests(node)
        [].tap do |digests|
          # The old google books use upcased versions. See https://argo.stanford.edu/view/druid:dd116zh0343
          # Web archive crawls use SHA1
          sha1 = node.xpath('checksum[@type="sha1" or @type="SHA1" or @type="SHA-1"]').text.presence
          digests << { type: 'sha1', digest: sha1 } if sha1
          md5 = node.xpath('checksum[@type="md5" or @type="MD5"]').text.presence
          digests << { type: 'md5', digest: md5 } if md5
        end
      end

      def build_files(file_nodes)
        file_nodes.map do |node|
          height = node.xpath('imageData/@height').text.presence&.to_i
          width = node.xpath('imageData/@width').text.presence&.to_i
          use = node.xpath('@role').text.presence
          {
            # External identifier is always generated because it is not stored in Fedora.
            externalIdentifier: IdGenerator.generate_file_id,
            type: Cocina::Models::Vocab.file,
            label: node['id'],
            filename: node['id'],
            size: node['size'].to_i,
            version: version,
            hasMessageDigests: digests(node),
            access: access(node['id']),
            administrative: {
              publish: node['publish'] == 'yes' || node['deliver'] == 'yes',
              sdrPreserve: node['preserve'] == 'yes',
              shelve: node['shelve'] == 'yes'
            }
          }.tap do |attrs|
            # Files from Goobi don't have mimetype until they hit exif-collect in the assemblyWF
            attrs[:hasMimeType] = node['mimetype'] if node['mimetype'].present?
            attrs[:presentation] = { height: height, width: width } if height && width
            attrs[:use] = use if use
          end
        end
      end

      def access(filename)
        file_specific_rights = rights_object.file[filename]
        return item_rights if file_specific_rights.nil?

        Access::AccessRights.props(file_specific_rights, rights_xml: rights_metadata.ng_xml.to_xml)
      end

      def item_rights
        rights = Access::AccessRights.props(rights_object, rights_xml: rights_metadata.ng_xml.to_xml)

        # File rights can't be citation-only, so if they are make dark.
        rights[:access] = 'dark' if rights[:access] == 'citation-only'
        rights
      end
    end
  end
end
