class Game < ActiveRecord::Base
  extend ActiveSupport::Memoizable

  BlockRange = 1..3
  MoveCount = 2
  EscapedTurn = 5
  UserGameCount = 5
  
  paginates_per 10

  attr_accessor :current_user

  belongs_to :fleer, :class_name => 'User'
  belongs_to :taker, :class_name => 'User'
  belongs_to :host, :class_name => 'User'
  has_many   :moves, :order => "turn asc", :dependent => :destroy
  has_many   :talks, :order => "talks.id", :dependent => :destroy

  validates :fleer, :taker, :host, :presence => true

  validate :validate_keys

  AppDataAttributes = [:key_x, :key_y, :fleer_win, :taker_win]

  def self.dump_app_data(hash_data, _data = {})
    _data ||= {}
    AppDataAttributes.map do |cd_attr|
      _data[cd_attr] = hash_data.symbolize_keys[cd_attr] if hash_data.symbolize_keys.has_key?(cd_attr)
    end
    ActiveSupport::Base64.encode64(Marshal.dump(_data))
  end

  def set_app_data(data)
    self.app_data = self.class.dump_app_data(data, load_app_data)
  end

  def load_app_data
    Marshal.load(ActiveSupport::Base64.decode64(self.app_data)) rescue {}
  end
  memoize :load_app_data

  def validate_keys
    return true if self.key_is_not_set?

    if !BlockRange.include?(self.load_app_data[:key_x].to_i) || !BlockRange.include?(self.load_app_data[:key_y].to_i)
      self.errors.add(:key_xy, :inclusion)
    end
  end

  def title
    "#{self.fleer_title} - #{self.taker_title}"
  end
  def fleer_title
    "Fleer##{self.fleer.login}"
  end
  def taker_title
    "Taker##{self.taker.login}"
  end

  def fleer_moves
    Array(fleer_or_taker_moves(1))
  end
  memoize :fleer_moves
  def fleer_turn(_reload = false)
    fleer_moves.present? ? fleer_moves(_reload).last.turn : 0
  end
  def taker_moves
    Array(fleer_or_taker_moves(2))
  end
  memoize :taker_moves
  def taker_turn(_reload = false)
    taker_moves.present? ? taker_moves(_reload).last.turn : 0
  end
  def fleer_or_taker_moves(_fleer_or_taker)
    self.moves.where(:fleer_or_taker => _fleer_or_taker).order(Move.arel_table[:turn].asc)
  end

  def current_user=(_user)
    if _user.id == self.fleer_id || _user.id == self.taker_id
      @current_user = _user
    end
  end
  def opposite
    self.try(opposite_s_side)
  end
  def user_s_side
    self.current_user.id == self.fleer_id ? :fleer : :taker
  end
  def opposite_s_side
    self.current_user.id == self.fleer_id ? :taker : :fleer
  end
  [:user, :opposite].map do |target|
    define_method "#{target}_xy" do
      self.try("current_#{try("#{target}_s_side")}_xy")
    end
    define_method "#{target}_moves" do
      self.try("#{try("#{target}_s_side")}_moves")
    end
    define_method "#{target}_turn" do
      self.try("#{target}_moves").last ?
            self.try("#{target}_moves").last.turn : 0
    end
  end
  def user_movable?
    self.opposite_turn >= self.user_turn
  end
  def opposite_moved?
    self.opposite_turn > self.user_turn
  end
  def show_opposite_move
    if self.opposite_turn <= self.user_turn
      self.opposite_moves.last
    else
      self.opposite_moves[-2]
    end
  end

  def current_fleer_xy
    self.fleer_moves.last ? self.fleer_moves.last.to_xy : self.fleer_init_xy
  end
  def fleer_init_xy
    [BlockRange.first,BlockRange.first]
  end
  def current_taker_xy
    self.taker_moves.last ? self.taker_moves.last.to_xy : self.taker_init_xy
  end
  def taker_init_xy
    [BlockRange.last,BlockRange.last]
  end
  def key_xy
    [load_app_data[:key_x], load_app_data[:key_y]]
  end
  def key_is_not_set?
    self.key_xy == [nil,nil]
  end

  def xy_text_and_class(xy)
    _text_and_class = {
      :text => [],
      :class => []
    }
    if self.user_xy == xy
      _text_and_class[:text] << self.current_user.login
      _text_and_class[:class] << self.user_s_side.to_s
    end
    if (self.show_opposite_move && self.show_opposite_move.to_xy == xy) ||
        (self.show_opposite_move.nil? && self.try("#{self.opposite_s_side}_init_xy") == xy)
      _text_and_class[:text] << self.opposite.login
      _text_and_class[:class] << self.opposite_s_side.to_s
    end
    if self.key_xy == xy
      _text_and_class[:text] << "Key"
      _text_and_class[:class] << "key"
    end

    return case
    when _text_and_class[:class].present?
      [_text_and_class[:text].join(" & "), _text_and_class[:class].join("_")]
    when self.movable?(xy)
      ["move", nil]
    else
      ["not moving", nil]
    end
  end

  def self.movable?(_from, _to)
    (_from[0].to_i.abs - _to[0].to_i.abs).abs + (_from[1].to_i.abs - _to[1].to_i.abs).abs <= MoveCount
  end
  def movable?(_to)
    return nil if self.user_xy.nil?
    self.class.movable?(self.user_xy, _to)
  end

  def user_move_build
    current_turn = self.try("#{self.user_s_side}_moves").last ?
          self.try("#{self.user_s_side}_moves").last.turn + 1 : 1

    _move = self.moves.build(
      :turn => current_turn,
      :fleer_or_taker => (self.user_s_side == :fleer ? 1 : 2)
    )
    _move.key_xy = self.key_xy
    rival_xy = nil
    self.try("#{self.opposite_s_side}_moves").map do |__move|
      next unless __move.turn == current_turn - 1
      rival_xy = __move.to_xy
    end
    rival_xy = self.try("#{self.opposite_s_side}_init_xy") if rival_xy.nil?
    _move.rival_xy = rival_xy
    _move
  end
  
  def finished?
    self.finish >= 1
  end
  def set_finished
    self.set_app_data(
      :fleer_win => self.fleer_win?,
      :taker_win => self.taker_win?
    )
    if load_app_data[:fleer_win] || load_app_data[:taker_win]
      if self.finish == 0
        self.finish = 1
      end
      if self.winner.blank?
        if load_app_data[:fleer_win]
          self.winner = 'fleer'
        end
        if load_app_data[:taker_win]
          self.winner = 'taker'
        end
      end
    end
    self.save(:validate => false)
  end
  def list_class
    case
    when !self.finished?
      nil
    when load_app_data[:fleer_win]
      "fwin"
    when load_app_data[:taker_win]
      "twin"
    end
  end

  # fleer winning
  # More than once to move 1 "fleer" and "key" in the same position.
  #  ("taker" in the same position if lost)
  # Turn "EscapedTurn" becomes more than.
  def fleer_win?
    self.winner == 'fleer' ||
    (
      self.fleer_turn > 0 &&
      self.fleer_turn == self.taker_turn &&
      self.current_fleer_xy != self.current_taker_xy &&
      self.key_xy == self.current_fleer_xy
    ) ||
    (
      !(
      self.fleer_turn == self.taker_turn &&
      self.current_fleer_xy == self.current_taker_xy
      ) &&
      self.fleer_turn >= EscapedTurn && self.taker_turn >= EscapedTurn
    )
  end

  # taker winning
  # "fleer" and "taker" has the same position.
  def taker_win?
    self.winner == 'taker' || (
    self.fleer_turn == self.taker_turn && 
    self.current_fleer_xy == self.current_taker_xy)
  end

  def winner_user
    case
    when self.fleer_win?
      self.fleer
    when self.taker_win?
      self.taker
    else
      nil
    end
  end

  def can_put_key?
    self.user_s_side == :taker && self.key_is_not_set?
  end

  def can_talk?
    self.current_user.present? &&
    self.talks.game_and_turn(self.id, self.current_user.id, self.user_turn).count < Talk::TalkPerTurn
  end

  def can_cancel?
    self.user_turn == 0
  end
end
