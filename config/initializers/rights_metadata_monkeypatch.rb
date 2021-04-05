# frozen_string_literal: true

module Dor
  # These templates live in DefaultObjectRights but not in the RightsMetadataDS
  #
  # We rely on them when mapping to Cocina
  class RightsMetadataDS < ActiveFedora::OmDatastream
    define_template(:use, &:use)
  end

  # Overwrite some definitions on the DefaultObjectRightsDS (used in AdminPolicies)
  class DefaultObjectRightsDS < ActiveFedora::OmDatastream
    define_template(:use, &:use)
  end
end
