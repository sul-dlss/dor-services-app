# frozen_string_literal: true

json.members @members do |member|
  json.externalIdentifier member['id']
  json.type member['objectType_ssim'].first
end
