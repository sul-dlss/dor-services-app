# frozen_string_literal: true

json.members @members do |member|
  json.externalIdentifier member.external_identifier
  json.version member.version
end
