# frozen_string_literal: true

# A Cocina-like object that wraps an invalid Cocina object
class InvalidCocina < Hashie::Mash
  include Hashie::Extensions::Mash::SymbolizeKeys

  disable_warnings :size
end
