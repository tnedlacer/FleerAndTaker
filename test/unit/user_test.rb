require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context "basic" do
    should have_many(:fleer_games)
    should have_many(:taker_games)
    should have_many(:talks)

    should "game" do
      u = Factory(:twitter_oauth_user)
      f1 = Factory(:game, :fleer_id => u.id)
      t1 = Factory(:game, :taker_id => u.id)
      User.find(u.id).games.map do |game|
        [f1.id, t1.id].include?(game.id)
      end
    end
  end
end
