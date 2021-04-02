# frozen_string_literal: true

module Dor
  # These templates live in DefaultObjectRights but not in the RightsMetadataDS
  #
  # We rely on them when mapping to Cocina
  class RightsMetadataDS < ActiveFedora::OmDatastream
    define_template :creative_commons do |xml|
      xml.human(type: 'creativeCommons')
      xml.machine(type: 'creativeCommons', uri: '')
    end

    define_template :open_data_commons do |xml|
      xml.human(type: 'openDataCommons')
      xml.machine(type: 'openDataCommons', uri: '')
    end

    define_template(:use, &:use)
  end
end
