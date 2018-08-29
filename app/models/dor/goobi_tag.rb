module Dor
  class GoobiTag
    attr_accessor :name, :value

    def initialize(p_hash)
      @name = p_hash[:name]
      @value = p_hash[:value]
    end
  end
end
