# frozen_string_literal: true

# This is necessary, so that Dor.find will cast etds to this type.
# Otherwise it'll say: Etd is not a real class
# and return a Dor::Item.
# This is necessary for the Cocina::Mapper because Etds do not use descMetadata
# like ever other object.
class Etd < Dor::Etd
  # This is required so that we can map from contentMetadata.
  # We need it because Dor::Etd's parent is Dor::Abstract rather than Dor::Item
  has_metadata name: 'contentMetadata',
               type: Dor::ContentMetadataDS,
               label: 'Content Metadata',
               control_group: 'M'
end
