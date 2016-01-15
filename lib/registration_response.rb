module Dor
  class RegistrationResponse
    def initialize(p_hash)
      @params = p_hash
    end

    def to_txt
      @params[:pid]
    end

    def to_json
      @params.to_json
    end
  end
end
