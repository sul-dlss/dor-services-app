# frozen_string_literal: true

# Validates the a druid is valid and starts with 'druid:'
class DruidValidator < ActiveModel::Validator
  def validate(record)
    return if DruidTools::Druid.valid?(record.druid, true) && record.druid.starts_with?('druid:')

    record.errors.add(:druid, 'is not valid')
  end
end
