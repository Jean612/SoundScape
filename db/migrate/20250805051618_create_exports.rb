class CreateExports < ActiveRecord::Migration[8.0]
  def change
    create_table :exports do |t|
      t.references :playlist, null: false, foreign_key: true
      t.string :platform
      t.string :external_id
      t.datetime :exported_at

      t.timestamps
    end
  end
end
