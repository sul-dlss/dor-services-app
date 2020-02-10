# frozen_string_literal: true

# This is necessary, so that Dor.find will cast etds to this type.
# Otherwise it'll say: Etd is not a real class
# and return a Dor::Item.
# This is necessary for the Cocina::Mapper because Etds do not use descMetadata
# like ever other object.
class Etd < Dor::Etd; end
