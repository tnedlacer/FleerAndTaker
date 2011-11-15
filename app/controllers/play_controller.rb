class PlayController < ApplicationController

  before_filter :login_required, :except => [:game]
  before_filter :find_opposite, :only => [:new, :create]
  before_filter :find_game, :only => [:move, :talk, :cancel, :give_up]
  before_filter :game_is_finished?, :only => [:move, :talk]

  def index
  end
  def accept_only_friends
    current_user.only_friends_toggle
    current_user.save!
    redirect_to :action => :index
  end

  def search
    if params[:name].present?
      @user_list = current_user.twitter_client.user_search(params[:name])
    else
      @user_list = [User.cpu] + current_user.twitter_client.friends.users
    end
  end

  private
    def find_opposite
      begin
        if params[:id] == '0'
          @opposite = User.cpu
        else
          @opposite = current_user.twitter_client.users(params[:id].to_i).first
        end
        if @opposite.id.to_i == current_user.twitter_id.to_i
          redirect_to :action => :search
          return
        end
      rescue Twitter::NotFound
        redirect_to :action => :search
      end
    end

  public
  def new
  end

  def create
    if current_user.too_many_games?
      flash[:notice] = "Too many games available."
    elsif params[:ft].blank? || ![1,2].include?(params[:ft].to_i)
      flash[:notice] = "Select Fleer or Taker"
    end
    if flash[:notice].present?
      redirect_to :action => :new, :id => params[:id]
      return
    end

    opp_user = User.where(User.arel_table[:twitter_id].eq(@opposite.id.to_s)).first
    if opp_user.nil?
      opp_user = User.new
      opp_user.twitter_id = @opposite.id.to_i
      opp_user.login = @opposite.screen_name
    elsif opp_user.accept_only_friends?
      _following = opp_user.twitter_client.users(current_user.twitter_id.to_i).first.following rescue false
      unless _following
        flash[:notice] = "Only friends are accepted #{opp_user.login}."
        redirect_to :action => :new, :id => params[:id]
        return
      end
    end

    if params[:ft].to_i == 1
      attrs = {:fleer => current_user, :taker => opp_user}
    else
      attrs = {:taker => current_user, :fleer => opp_user}
    end

    g = Game.new(attrs.merge(:host_id => current_user))
    g.save
    redirect_to play_game_path(g.id)
  end

  private
    def find_game
      begin
        @game = current_user.games.find(params[:id])
        @game.current_user = current_user
      rescue ActiveRecord::RecordNotFound
        redirect_to :action => :index
      end
    end
    def game_is_finished?
      if @game.finished?
        flash[:notice] = "The game ended"
        redirect_to play_game_path(@game.id)
        return
      end
    end
  public
  def game
    @game = Game.find(params[:id])
    if current_user && [@game.fleer_id, @game.taker_id].include?(current_user.id)
      @game.current_user = current_user
    end
  end

  def move
    if params[:key].to_i == 1
      set_key
    else
      if params[:x].blank? || params[:y].blank? ||
          !@game.movable?([params[:x], params[:y]]) || !@game.user_movable?
        flash[:move] = "Not Moving!!"
      else
        _move = @game.user_move_build
        _move.to_xy = [params[:x],params[:y]]
        _move.save!
        flash[:move] = "Move!!"
        if @game.opposite == User.cpu
          @game.current_user = @game.opposite
          move_candidate = []
          Game::BlockRange.map do |y|
            Game::BlockRange.map do |x|
              move_candidate << [x,y] if @game.movable?([x,y])
            end
          end
          _move_cpu = @game.user_move_build
          _move_cpu.to_xy = move_candidate[rand(move_candidate.size)]
          _move_cpu.save!
          flash[:move] = "You & CPU Move!!"
          if @game.can_put_key? && 1 == rand(2)
            set_key_candidate = []
            Game::BlockRange.map do |y|
              Game::BlockRange.map do |x|
                set_key_candidate << [x,y]
              end
            end
            set_key_xy = set_key_candidate[rand(set_key_candidate.size)]
            @game.set_app_data({:key_x => set_key_xy.first, :key_y => set_key_xy.last})
            @game.save!(:validate => false)
            flash[:move] << " CPU Set key!!"
          end
        end
      end
    end
    redirect_to play_game_path(@game.id)
  end
  private
    def set_key
      if params[:x].present? && params[:y].present? &&
        @game.can_put_key?
        @game.set_app_data({:key_x => params[:x].to_i, :key_y => params[:y].to_i})
        if @game.valid? && @game.save!(:validate => false)
          flash[:move] = "Set key!!"
          return
        end
      end
      flash[:move] = "Unable to set key!!"
    end

  public
  def talk
    @talk = current_user.talks.build(:game => @game)
    @talk.turn = @game.user_turn
    @talk.say = {
      :message => params[:message],
      :block => params[:block]
    }
    if @talk.valid? && @talk.save!(:validate => false)
      redirect_to play_game_path(@game.id)
    else
      render :action => :game
    end
  end

  def cancel
    unless @game.can_cancel?
      flash[:notice] = "This game can not be canceled."
      redirect_to play_game_path(@game.id)
    end
    @game.destroy
    redirect_to :action => :index
  end
  def give_up
    @game.finish = 2
    @game.winner = @game.opposite_s_side.to_s
    @game.set_finished
    redirect_to play_game_path(@game.id)
  end

#  def tweet
#    _return_to = params[:r].present? ? params[:r] : url_for(:action => :index)
#    if params[:t].present?
#      current_user.twitter_client.update(params[:t])
#      flash[:notice] = 'Tweet!!'
#    end
#    redirect_to _return_to
#  end
  
end
