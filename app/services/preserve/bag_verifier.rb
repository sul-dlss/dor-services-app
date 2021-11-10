# frozen_string_literal: true

module Preserve
  # This checks to ensure the bag is well formed
  class BagVerifier
    REQUIRED_FILES = %w[
      data
      bagit.txt
      bag-info.txt
      manifest-sha256.txt
      tagmanifest-sha256.txt
      versionAdditions.xml
      versionInventory.xml
      data/metadata/versionMetadata.xml
    ].freeze

    # @param [Pathname] bag_dir the location of the bag to be verified
    # @return [Boolean] true if all required files exist
    # @raises [StandardError] a required file is missing
    def self.verify(directory:)
      new(directory: directory).verify
    end

    def initialize(directory:)
      @directory = directory
    end

    attr_reader :directory

    def verify
      verify_pathname(directory)
      REQUIRED_FILES.each do |path|
        verify_pathname(directory.join(path))
      end
      true
    end

    # @param [Pathname] pathname The file whose existence should be verified
    # @return [Boolean] true if file exists, raises exception if not
    def verify_pathname(pathname)
      raise "#{pathname.basename} not found at #{pathname}" unless pathname.exist?

      true
    end
  end
end
