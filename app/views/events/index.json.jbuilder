# frozen_string_literal: true

json.array! @events, :event_type, :druid, :data, :created_at
