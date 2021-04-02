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

  # Overwrite some definitions on the DefaultObjectRightsDS (used in AdminPolicies)
  class DefaultObjectRightsDS < ActiveFedora::OmDatastream
    # Here we patch in the "use" node definition.
    set_terminology do |t|
      t.root path: 'rightsMetadata', index_as: [:not_searchable]
      t.copyright path: 'copyright/human', index_as: [:symbol]
      t.use_statement path: '/use/human[@type=\'useAndReproduction\']', index_as: [:symbol]

      t.use do
        t.machine
        t.human
      end

      t.creative_commons path: '/use/machine[@type=\'creativeCommons\']', type: 'creativeCommons' do
        t.uri path: '@uri'
      end
      t.creative_commons_human path: '/use/human[@type=\'creativeCommons\']'
      t.open_data_commons path: '/use/machine[@type=\'openDataCommons\']', type: 'openDataCommons' do
        t.uri path: '@uri'
      end
      t.open_data_commons_human path: '/use/human[@type=\'openDataCommons\']'
    end

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
