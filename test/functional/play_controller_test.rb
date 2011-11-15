# -*- coding: utf-8 -*-
require 'test_helper'

class PlayControllerTest < ActionController::TestCase
  include FunctionalTestExt
  
  context "not sigged in" do
    should "get index" do
      get :index
      assert_response :redirect
    end
  end

  context "sigged in" do
    setup do
      @controller.stubs(:find_opposite).returns(true)
      @opposite = stub(:id => Factory.next(:twitter_id), :screen_name => Factory.next(:twitter_login), :profile_image_url => 'test.gif')
      @controller.instance_variable_set(:@opposite, @opposite)
      tlogin
    end
    should "get index" do
      get :index
      assert_response :success
    end
    should "get new" do
      get :new, :id => @opposite.id
      assert_response :success
    end
    context "post create" do
      should "fleer or taker blank" do
        post :create, :id => @opposite.id
        assert_response :redirect
        assert_redirected_to :action => :new, :id => @opposite.id
        set_the_flash.to("Check Fleer or Taker")
      end
      should "opp_user nil" do
        assert_difference "User.count" do
          post :create, :id => @opposite.id, :ft => 1
        end
        new_user = User.find_by_twitter_id(@opposite.id)
        assert_response :redirect
        assert_redirected_to :action => :game, :id => new_user.games.last.id
      end
      should "opp_user found" do
        user = Factory(:twitter_oauth_user, :twitter_id => @opposite.id)
        assert_no_difference "User.count" do
          post :create, :id => @opposite.id, :ft => 1
        end
        assert_response :redirect
        assert_redirected_to :action => :game, :id => user.games.last.id
      end
    end
    context "get game" do
      should "mygame" do
        g = Factory(:game, :fleer => @user)
        get :game, :id => g.id
        assert_response :success
      end
      should "other game" do
        g = Factory(:game)
        get :game, :id => g.id
        assert_response :success
      end
    end
    context "post move" do
      context "move" do
        setup do
          @game = Factory(:game, :fleer => @user)
          @game.current_user = @user
        end
        should "movable" do
          assert_difference "@game.moves.count" do
            post :move, :id => @game.id, :x => 2, :y => 2
          end
          assert_response :redirect
        end
        should "x y blank" do
          assert_no_difference "@game.moves.count" do
            post :move, :id => @game.id
          end
          assert_response :redirect
        end
        should "x y not movable" do
          assert_no_difference "@game.moves.count" do
            post :move, :id => @game.id, :x => 3, :y => 3
          end
          assert !@game.movable?([3,3])
          assert_response :redirect
        end
        should "@user not moving" do
          2.times do
            _move = @game.user_move_build
            _move.to_xy = [1,1]
            _move.save!
            @game = Game.find(@game.id)
            @game.current_user = @user
          end
          assert_no_difference "@game.moves.count" do
            post :move, :id => @game.id, :x => 1, :y => 1
          end
          assert !@game.user_movable?
          assert_response :redirect
        end
        should "game_is_finished" do
          game_is_finished(:move)
        end
      end
      context "set key" do
        setup do
          @game = Factory(:game, :taker => @user, :app_data => nil, :moves => [])
          @game.current_user = @user
          assert @game.key_is_not_set?
        end
        should "ok" do
          post :move, :id => @game.id, :x => 2, :y => 2, :key => 1
          assert_response :redirect
          game = Game.find(@game.id)
          assert_equal game.key_xy, [2,2]
        end
        should "x y blank" do
          post :move, :id => @game.id, :key => 1
          assert_response :redirect
          assert @game.key_is_not_set?
          assert_equal flash[:move], "Unable to set key!!"
        end
        should "fleer" do
          @game.taker = @game.fleer
          @game.fleer = @user
          @game.save!
          post :move, :id => @game.id, :x => 2, :y => 2, :key => 1
          assert_response :redirect
          assert @game.key_is_not_set?
          assert_equal flash[:move], "Unable to set key!!"
        end
        should "key has been set" do
          @game.set_app_data({:key_x => 1, :key_y => 2})
          @game.save!
          post :move, :id => @game.id, :x => 2, :y => 2, :key => 1
          assert_response :redirect
          assert_equal flash[:move], "Unable to set key!!"
          game = Game.find(@game.id)
          assert_equal game.key_xy, [1,2]
        end
        # set key test
      end
    end
    context "post talk" do
      setup do
        @game = Factory(:game, :fleer => @user)
        @game.current_user = @user
      end
      should "talk message and block" do
        post_talk_test(:message => 'あああ', :block => {'1_2' => "いいい"})
      end
      should "talk message" do
        post_talk_test(:message => 'あああ')
      end
      should "talk block" do
        post_talk_test(:message => 'あああ', :block => {'1_2' => "いいい"})
      end
      should "say blank" do
        assert_no_difference "@game.talks.count" do
          post :talk, :id => @game.id
        end
        assert_response :success
      end
      should "3 times per turn" do
        3.times do
          Factory(:fleer_talk, :game => @game, :turn => @game.user_turn)
        end
        assert_no_difference "@game.talks.count" do
          post :talk, :id => @game.id, :message => 'あああ'
        end
        assert_response :success
      end
      should "game_is_finished" do
        game_is_finished(:talk)
      end
    end
  end
  private
    def post_talk_test(_params)
      assert_difference "@game.talks.count" do
        post :talk, {:id => @game.id}.merge(_params)
      end
      assert_response :redirect
    end

    def game_is_finished(_action)
      @game.current_user = @game.fleer
      move1 = @game.user_move_build
      move1.to_xy = [1,1]
      move1.save!

      @game.current_user = @game.taker
      move2 = @game.user_move_build
      move2.to_xy = [1,1]
      move2.save!
      post _action, :id => @game.id
      assert_equal flash[:notice], "The game ended"
      assert_response :redirect
    end
  
end
