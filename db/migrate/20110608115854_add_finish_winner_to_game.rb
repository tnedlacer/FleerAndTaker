class AddFinishWinnerToGame < ActiveRecord::Migration
  def self.up
    add_column :games, :finish, :integer, :default => 0
    add_column :games, :winner, :string
  end

  def self.down
    remove_column :games, :winner
    remove_column :games, :finish
  end
end
