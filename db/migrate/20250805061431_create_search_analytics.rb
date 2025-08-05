class CreateSearchAnalytics < ActiveRecord::Migration[8.0]
  def change
    create_table :search_analytics do |t|
      t.references :user, null: false, foreign_key: true
      t.string :query
      t.datetime :searched_at
      t.string :ip_address
      t.integer :results_count

      t.timestamps
    end
  end
end
