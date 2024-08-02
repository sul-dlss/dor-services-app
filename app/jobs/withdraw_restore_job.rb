# frozen_string_literal: true

# Withdraws / restores a version from PURL
class WithdrawRestoreJob < ApplicationJob
  queue_as :default

  def perform(user_version:)
    druid = user_version.repository_object_version.repository_object.external_identifier
    version = user_version.version
    if user_version.withdrawn
      PurlFetcher::Client::Withdraw.withdraw(druid:, version:)
    else
      PurlFetcher::Client::Withdraw.restore(druid:, version:)
    end
  end
end
