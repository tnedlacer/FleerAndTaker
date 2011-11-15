class CreateTalks < ActiveRecord::Migration
  def self.up
    create_table :talks do |t|
      t.belongs_to :game, :user
      t.integer :turn
      t.text :say
      t.timestamps
    end
  end

  def self.down
    drop_table :talks
  end
end
