class AddHostIdToGame < ActiveRecord::Migration
  def self.up
    add_column :games, :host_id, :integer
  end

  def self.down
    remove_column :games, :host_id
  end
end
