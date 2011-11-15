class User < TwitterAuth::GenericUser
  # Extend and define your user model as you see fit.
  # All of the authentication logic is handled by the 
  # parent TwitterAuth::GenericUser class.

  has_many :fleer_games, :foreign_key => :fleer_id, :class_name => "Game"
  has_many :taker_games, :foreign_key => :taker_id, :class_name => "Game"

  has_many :talks

  CPU_ID = 0
  def self.cpu
    @user_cpu = Rails.cache.read('user_cpu')
    if @user_cpu.nil?
      @user_cpu = self.find(CPU_ID)
      Rails.cache.write(@user_cpu, 'user_cpu', :expires_in => 1.days )
    end
    @user_cpu
  end

  def games
    Game.where(Game.arel_table[:fleer_id].eq(self.id).or(Game.arel_table[:taker_id].eq(self.id))).order(Game.arel_table[:id].desc)
  end
  def my_games
    Game.where(Game.arel_table[:host_id].eq(self.id))
  end
  def active_my_games
    self.my_games.where(Game.arel_table[:finish].eq(0))
  end
  def too_many_games?
    self.active_my_games.count > Game::UserGameCount
  end

  def twitter_client
    Twitter::Client.new(:oauth_token => self.access_token, :oauth_token_secret => self.access_secret)
  end

  def win_games
    win_loss_games(true)
  end
  def loss_games
    win_loss_games(false)
  end
  def win_loss_games(win = true)
    Game.where(
      Game.arel_table[:fleer_id].eq(self.id).and(Game.arel_table[:winner].eq(win ? 'fleer' : 'taker')).
        or(Game.arel_table[:taker_id].eq(self.id).and(Game.arel_table[:winner].eq(win ? 'taker' : 'fleer')))
    )
  end

  def only_friends_toggle
    self.only_friends = (self.only_friends == 1 ? 0 : 1)
  end
  def accept_only_friends?
    self.only_friends == 1
  end
end
