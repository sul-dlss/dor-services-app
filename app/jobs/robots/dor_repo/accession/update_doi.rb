# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Update DOI metadata at Datacite for items with DOIs
      class UpdateDoi < Robots::Robot
        def initialize
          super('accessionWF', 'update-doi')
        end

        def perform_work # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
          unless cocina_object.dro?
            return LyberCore::ReturnState.new(status: :skipped,
                                              note: 'DOIs are not supported on non-Item objects')
          end
          return LyberCore::ReturnState.new(status: :skipped, note: 'Object does not have a DOI') unless doi

          if cocina_object.administrative.hasAdminPolicy == Settings.graveyard_admin_policy.druid
            return LyberCore::ReturnState.new(status: :skipped,
                                              note: 'Object belongs to the SDR graveyard APO')
          end

          # Check to see if these meet the conditions necessary to export to datacite
          unless Cocina::ToDatacite::Attributes.exportable?(cocina_object)
            raise "Item requested a DOI be updated, but it doesn't meet all the preconditions. " \
                  'Datacite requires that this object have creators and a datacite extension with resourceTypeGeneral'
          end
          attributes = Cocina::ToDatacite::Attributes.mapped_from_cocina(Cocina::Models.without_metadata(cocina_object))

          Honeybadger.context(attributes:, doi:, druid:)

          result = client.update(id: doi, attributes: attributes.deep_stringify_keys)
          return if result.success?

          raise "Error connecting to datacite (#{druid}) " \
                "response: #{result.failure.status}: #{result.failure.body}\n" \
                "request: #{result.failure.env.request_body}"
        end

        def doi
          @doi ||= cocina_object.identification&.doi
        end

        def client
          Datacite::Client.new(username: Settings.datacite.username,
                               password: Settings.datacite.password,
                               host: Settings.datacite.host)
        end
      end
    end
  end
end
