# frozen_string_literal: true

Rails.autoloaders.each do |autoloader|
  autoloader.inflector.inflect(
    'marc_relators' => 'MARC_RELATORS'
  )
end
