# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the FileSet instance from a Dor::Item
    class FileSets
      def self.build(content_metadata_ds, version:)
        content_metadata_ds.ng_xml.xpath('//resource[file]').map do |resource_node|
          files = build_files(resource_node.xpath('file'), version: version)
          structural = {}
          structural[:contains] = files if files.present?
          {
            externalIdentifier: IdGenerator.generate_or_existing_fileset_id(resource_node['id']),
            type: resource_type(resource_node),
            version: version,
            structural: structural
          }.tap do |attrs|
            label = resource_node.xpath('label').text
            # Use external identifier if label blank (which it is at least for some WAS Crawls).
            attrs[:label] = label.presence || attrs[:externalIdentifier]
          end
        end
      end

      def self.resource_type(resource_node)
        val = resource_node['type']&.underscore
        val = 'three_dimensional' if val == '3d'
        if val && Cocina::Models::Vocab::Resources.respond_to?(val)
          Cocina::Models::Vocab::Resources.public_send(val)
        else
          Honeybadger.notify("Invalid resource type: '#{val}'")
          Cocina::Models::Vocab::Resources.file
        end
      end

      def self.digests(node)
        [].tap do |digests|
          # The old google books use upcased versions. See https://argo.stanford.edu/view/druid:dd116zh0343
          # Web archive crawls use SHA1
          sha1 = node.xpath('checksum[@type="sha1" or @type="SHA1" or @type="SHA-1"]').text.presence
          digests << { type: 'sha1', digest: sha1 } if sha1
          md5 = node.xpath('checksum[@type="md5" or @type="MD5"]').text.presence
          digests << { type: 'md5', digest: md5 } if md5
        end
      end

      def self.build_files(file_nodes, version:)
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
            access: access(node),
            administrative: {
              publish: node['publish'] == 'yes',
              sdrPreserve: node['preserve'] == 'yes',
              shelve: node['shelve'] == 'yes'
            }
          }.tap do |attrs|
            # Files from Goobi and Hydrus don't have mimetype until they hit exif-collect in the assemblyWF
            attrs[:hasMimeType] = node['mimetype'] if node['mimetype']
            attrs[:presentation] = { height: height, width: width } if height && width
            attrs[:use] = use if use
          end
        end
      end

      def self.access(node)
        if node['publish'] == 'yes'
          { access: 'world', download: 'world' }
        else
          { access: 'dark', download: 'none' }
        end
      end
    end
  end
end
