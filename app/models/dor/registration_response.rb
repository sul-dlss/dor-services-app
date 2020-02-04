# frozen_string_literal: true

module Dor
  class RegistrationResponse
    attr_reader :params
    delegate :to_json, to: :params

    def initialize(p_hash)
      @params = p_hash
    end

    def to_txt
      @params[:pid]
    end

    def location
      @params[:location]
    end
  end
end
