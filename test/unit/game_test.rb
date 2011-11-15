require 'test_helper'

class GameTest < ActiveSupport::TestCase
  context "basic" do
    should belong_to(:fleer)
    should belong_to(:taker)
    should belong_to(:host)
    should have_many(:moves)
    should validate_presence_of(:fleer)
    should validate_presence_of(:taker)
    should validate_presence_of(:host)
    should_not validate_presence_of(:app_data)

    should "app_data_dump" do
      _app_data = {:key_x => 2, :key_y => 1}
      game1 = Factory(:game)
      game1.set_app_data(_app_data)
      game1.save!
      assert_equal _app_data, Game.find(game1.id).load_app_data
    end
    should "validate_keys" do
      game = Factory(:game)
      assert game.valid?

      Game::BlockRange.map do |x|
        Game::BlockRange.map do |y|
          game.set_app_data({:key_x => x, :key_y => y})
          assert game.valid?
        end
      end
      [
        [Game::BlockRange.last + 1, 1],
        [1, Game::BlockRange.last + 1],
        [Game::BlockRange.last + 1, Game::BlockRange.last + 1],
      ].map do |x, y|
        game.set_app_data({:key_x => x, :key_y => y})
        assert !game.valid?
        assert game.errors[:key_xy].present?
      end

      game.set_app_data({:key_x => 1, :key_y => 1})
      assert game.valid?
    end
  end
  context "win" do
    context "fleer_win" do
      should "get key" do
        game = Factory(:game)
        
        assert !game.finished?
        assert !game.load_app_data[:fin]
        
        game.current_user = game.fleer
        move1 = game.user_move_build
        move1.to_xy = game.key_xy
        move1.save!
        game = Game.find(game.id)

        assert !game.finished?

        game.current_user = game.taker
        move2 = game.user_move_build
        move2.to_xy = [1,1]
        move2.save!
        game = Game.find(game.id)
    
        assert game.fleer_win?
        assert game.finished?
        assert game.load_app_data[:fleer_win]
        assert !game.load_app_data[:taker_win]
      end

      should "end of turn" do
        game = Factory(:game)
        assert !game.fleer_win?
        assert !game.finished?

        ((game.fleer_turn + 1)..Game::EscapedTurn).map do |i|
          game.current_user = game.fleer
          move1 = game.user_move_build
          move1.to_xy = [1,1]
          move1.save!
          game.current_user = game.taker
          move2 = game.user_move_build
          move2.to_xy = [2,2]
          move2.save!
          game = Game.find(game.id)
          assert_equal game.fleer_win?, i >= Game::EscapedTurn
          assert_equal game.finished?, i >= Game::EscapedTurn
        end
        assert game.finished?
        assert game.load_app_data[:fleer_win]
        assert !game.load_app_data[:taker_win]
      end

    end
    context "taker_win" do
      should "catch fleer" do
        game = Factory(:game)
        
        assert !game.finished?
        assert !game.finished?
        
        game.current_user = game.fleer
        move1 = game.user_move_build
        move1.to_xy = [1,1]
        move1.save!
        game = Game.find(game.id)

        assert !game.finished?

        game.current_user = game.taker
        move2 = game.user_move_build
        move2.to_xy = [1,1]
        move2.save!
        game = Game.find(game.id)
    
        assert game.taker_win?
        assert game.finished?
        assert !game.load_app_data[:fleer_win]
        assert game.load_app_data[:taker_win]
      end

      should "end of turn and cache" do
        game = Factory(:game)
        assert !game.fleer_win?
        assert !game.finished?

        ((game.fleer_turn + 1)..(Game::EscapedTurn - 1)).map do |i|
          game.current_user = game.fleer
          move1 = game.user_move_build
          move1.to_xy = [1,1]
          move1.save!
          game.current_user = game.taker
          move2 = game.user_move_build
          move2.to_xy = [2,2]
          move2.save!
          game = Game.find(game.id)
          assert_equal game.fleer_win?, i >= Game::EscapedTurn
          assert_equal game.finished?, i >= Game::EscapedTurn
        end
        game.current_user = game.fleer
        move1 = game.user_move_build
        move1.to_xy = [1,1]
        move1.save!
        game = Game.find(game.id)

        assert !game.finished?

        game.current_user = game.taker
        move2 = game.user_move_build
        move2.to_xy = [1,1]
        move2.save!
        game = Game.find(game.id)

        assert game.taker_win?
        assert game.finished?
        assert !game.load_app_data[:fleer_win]
        assert game.load_app_data[:taker_win]
      end
      
    end
  end
end
