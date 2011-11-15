class CreateMoves < ActiveRecord::Migration
  def self.up
    create_table :moves do |t|
      t.belongs_to :game
      t.integer :turn, :fleer_or_taker, :to_x, :to_y,
        :key_x, :key_y, :rival_x, :rival_y
      t.timestamps
    end
  end

  def self.down
    drop_table :moves
  end
end
