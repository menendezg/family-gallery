class CreateFolders < ActiveRecord::Migration[8.1]
  def change
    create_table :folders do |t|
      t.string :name, null: false
      t.text :description
      t.references :user, foreign_key: true

      t.timestamps
    end
  end
end
