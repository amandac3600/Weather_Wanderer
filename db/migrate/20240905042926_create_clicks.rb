class CreateClicks < ActiveRecord::Migration[7.2]
  def change
    create_table :clicks do |t|
      t.integer :total_clicks

      t.timestamps
    end
  end
end
