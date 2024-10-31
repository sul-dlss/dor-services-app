# frozen_string_literal: true

module Robots
  module DorRepo
    module Accession
      # Requests that Orcid works be created / updated for the object
      class UpdateOrcidWork < Robots::Robot
        def initialize
          super('accessionWF', 'update-orcid-work')
        end

        def perform_work
          return LyberCore::ReturnState.new(status: :skipped, note: 'Orcid works are not supported on non-Item objects') unless cocina_object.dro?
          return LyberCore::ReturnState.new(status: :skipped, note: 'Object belongs to the SDR graveyard APO') if cocina_object.administrative.hasAdminPolicy == Settings.graveyard_admin_policy.druid

          create_or_update_orcid_works
          delete_orcid_works
        end

        private

        def create_or_update_orcid_works
          orcid_users.each do |orcid_user|
            ar_orcid_work = OrcidWork.find_by(orcidid: orcid_user.orcidid, druid:)
            if ar_orcid_work.nil?
              create(orcid_user)
            elsif ar_orcid_work.md5 != md5
              update(orcid_user, ar_orcid_work)
            else
              Rails.logger.info("Orcid work for #{druid} / #{orcid_user.orcidid} has not changed")
            end
          end
        end

        def delete_orcid_works
          delete_orcid_users.each do |orcid_user|
            ar_orcid_work = OrcidWork.find_by(orcidid: orcid_user.orcidid, druid:)

            Rails.logger.info("Deleting Orcid work for #{druid} / #{orcid_user.orcidid}")
            orcid_client.delete_work(orcidid: orcid_user.orcidid, token: orcid_user.access_token, put_code: ar_orcid_work.put_code)
            ar_orcid_work.destroy
          end
        end

        def orcid_client
          @orcid_client ||= SulOrcidClient.configure(
            client_id: Settings.orcid.client_id,
            client_secret: Settings.orcid.client_secret,
            base_url: Settings.orcid.base_url,
            base_public_url: Settings.orcid.base_public_url,
            base_auth_url: Settings.orcid.base_auth_url
          )
        end

        def mais_orcid_client
          @mais_orcid_client = MaisOrcidClient.configure(
            client_id: Settings.mais_orcid.client_id,
            client_secret: Settings.mais_orcid.client_secret,
            base_url: Settings.mais_orcid.base_url
          )
        end

        def orcid_users
          @orcid_users ||= begin
            cited_orcid_ids = SulOrcidClient::CocinaSupport.cited_orcidids(cocina_object.description)

            all_orcid_users = cited_orcid_ids.filter_map do |orcid_id|
              mais_orcid_client.fetch_orcid_user(orcidid: orcid_id)
            end

            all_orcid_users.select(&:update?)
          end
        end

        def delete_orcid_users
          @delete_orcid_users ||= begin
            delete_ar_orcid_works = OrcidWork.where(druid:)
            orcid_ids = orcid_users.map(&:orcidid)
            delete_ar_orcid_works = delete_ar_orcid_works.where.not(orcidid: orcid_ids) if orcid_ids.present?

            delete_orcid_users = delete_ar_orcid_works.filter_map do |ar_orcid_work|
              mais_orcid_client.fetch_orcid_user(orcidid: ar_orcid_work.orcidid)
            end

            delete_orcid_users.select(&:update?)
          end
        end

        def work
          @work ||= SulOrcidClient::WorkMapper.map(description: cocina_object.description, doi: cocina_object.identification.doi)
        end

        def md5
          @md5 ||= Digest::MD5.hexdigest(work.to_json)
        end

        def create(orcid_user)
          Rails.logger.info("Creating new Orcid work for #{druid} / #{orcid_user.orcidid}")
          put_code = orcid_client.add_work(orcidid: orcid_user.orcidid, work:, token: orcid_user.access_token)
          OrcidWork.create(orcidid: orcid_user.orcidid, druid:, put_code:, md5:)
        end

        def update(orcid_user, ar_orcid_work)
          Rails.logger.info("Updating Orcid work for #{druid} / #{orcid_user.orcidid}")
          orcid_client.update_work(orcidid: orcid_user.orcidid, work:, token: orcid_user.access_token, put_code: ar_orcid_work.put_code)
          ar_orcid_work.update(md5:)
        end
      end
    end
  end
end
