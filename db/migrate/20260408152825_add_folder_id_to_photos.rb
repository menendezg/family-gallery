class AddFolderIdToPhotos < ActiveRecord::Migration[8.1]
  def change
    add_reference :photos, :folder, foreign_key: true
  end
end
