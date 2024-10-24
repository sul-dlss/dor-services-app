# frozen_string_literal: true

module Robots
  # Base class for DSA robots.
  class Robot < LyberCore::Robot
    def cocina_object
      @cocina_object ||= CocinaObjectStore.find(druid)
    end

    def object_client
      raise 'Object Client should not be used from a DSA robot'
    end
  end
end
