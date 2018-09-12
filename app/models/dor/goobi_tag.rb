module Dor
  # This represents a tag from Argo that we want to pass to Goobi.
  # So the tag from Argo:
  #   Process : Content Type : Image
  # Is represented as:
  #   <tag name="Process" value="Content Type : Image"></tag>
  class GoobiTag
    attr_accessor :name, :value

    def initialize(p_hash)
      @name = p_hash[:name]
      @value = p_hash[:value]
    end

    def to_xml
      "<tag name=\"#{name}\" value=\"#{value}\"></tag>"
    end
  end
end
