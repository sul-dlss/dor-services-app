class ChangeRepositoryObjectVersionCocinaVersionToString < ActiveRecord::Migration[7.1]
  def change
    change_column :repository_object_versions, :cocina_version, :string
  end
end
