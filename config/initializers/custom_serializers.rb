# frozen_string_literal: true

Rails.application.reloader.to_prepare do
  # Add our cocina-models serializer
  Rails.application.config.active_job.custom_serializers << Cocina::Serializer
end
