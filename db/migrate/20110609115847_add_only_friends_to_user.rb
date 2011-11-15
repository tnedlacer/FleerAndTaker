class AddOnlyFriendsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :only_friends, :integer, :default => 0
  end

  def self.down
    remove_column :users, :only_friends
  end
end
