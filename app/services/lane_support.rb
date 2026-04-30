# frozen_string_literal: true

# Support for lane selection.
class LaneSupport
  def self.lane_for(lane_id, prefix: nil)
    lane = ['low', 'high'].include?(lane_id) ? lane_id : 'default'
    lane = "#{prefix}_#{lane}" if prefix
    lane.to_sym
  end
end
