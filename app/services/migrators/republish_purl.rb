# frozen_string_literal: true

module Migrators
  # Migrator that will be used to remove release tags.
  class RepublishPurl < Base
    def migrate?
      return false unless repository_object.dro?

      invalid_purl_cocina_object?
    end

    def migrate
      transfer_to_document_store(public_cocina.to_json, 'cocina.json')
      PurlFetcher::Client::LegacyPublish.publish(cocina: public_cocina)
    end

    private

    def connection
      @connection ||= Faraday.new(url: Purl.base_url)
    end

    def bare_druid
      repository_object.external_identifier.delete_prefix('druid:')
    end

    def purl_druid
      @purl_druid ||= DruidTools::PurlDruid.new repository_object.external_identifier, Settings.stacks.local_document_cache_root
    end

    def invalid_purl_cocina_object?
      response = connection.get("/#{bare_druid}.json")
      return false unless response.success?

      Cocina::Models.build(JSON.parse(response.body))
      puts "#{repository_object.external_identifier} SKIPPED: Valid cocina object."
      false
    rescue Cocina::Models::ValidationError
      puts "#{repository_object.external_identifier} MIGRATING: Invalid cocina object."
      true
    end

    def cocina_object
      @cocina_object ||= repository_object.head_version.to_cocina
    end

    def public_cocina
      @public_cocina ||= Publish::PublicCocinaService.create(cocina_object)
    end

    # Create a file inside the content directory under the stacks.local_document_cache_root
    # @param [String] content The contents of the file to be created
    # @param [String] filename The name of the file to be created
    # @return [void]
    def transfer_to_document_store(content, filename)
      new_file = File.join(purl_druid.content_dir, filename)
      Rails.logger.debug("[Publish][#{repository_object.external_identifier}] Writing #{new_file}")
      File.write(new_file, content)
    end
  end
end
