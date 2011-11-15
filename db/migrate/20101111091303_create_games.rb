class CreateGames < ActiveRecord::Migration
  def self.up
    create_table :games do |t|
      t.integer :fleer_id, :taker_id
      t.text :app_data
      t.timestamps
    end
  end

  def self.down
    drop_table :games
  end
end
