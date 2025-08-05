class CreateSongs < ActiveRecord::Migration[8.0]
  def change
    create_table :songs do |t|
      t.string :title
      t.string :artist
      t.string :album
      t.integer :duration_seconds
      t.string :spotify_id
      t.string :youtube_id

      t.timestamps
    end
  end
end
