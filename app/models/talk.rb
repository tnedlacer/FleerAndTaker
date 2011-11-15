# -*- coding: utf-8 -*-
class Talk < ActiveRecord::Base
  # {:message => '', :block => { '1_1' => '', '1_2' => '' }}
  serialize :say, Hash

  TalkPerTurn = 3
  scope :game_and_turn, proc{|game_id, user_id, turn|
    where(
      self.arel_table[:game_id].eq(game_id).and(
        self.arel_table[:user_id].eq(user_id)
      ).and(
        self.arel_table[:turn].eq(turn)
      )
    )
  }

  belongs_to :game
  belongs_to :user

  validates :game, :user, :say, :presence => true
  validates :turn, :presence => true, :numericality => {:greater_than => 0}
  validate :validate_user_eq_game_user, :validate_turn_count,
    :validate_say_message, :validate_say_block_text

  def validate_user_eq_game_user
    return true if self.user.blank?
    return true if self.game.blank?

    if self.user != self.game.fleer && self.user != self.game.taker
      self.errors.add(:user, "user is not game user")
    end
  end

  def validate_turn_count
    return true if TalkPerTurn > self.same_turn_count
    self.errors.add(:turn, "#{TalkPerTurn} times per turn")
  end

  def validate_say_message
    return true if self.say_message.blank?

    # A large letter "split" so as not to use the memory in "size" in comparison to earlier
    if self.say[:message].to_s.size > 2000 || self.say[:message].to_s.split(//).size > 500
      self.errors.add(:say, :too_long, :count => 500)
    end

  end

  def validate_say_block_text
    return true if self.say_block.blank?

    error_flag = false
    self.say[:block].map do |xy, text|
      xy_a = xy.split('_')
      if xy_a.size == 2
        if !Game::BlockRange.include?(xy_a[0].to_i) || !Game::BlockRange.include?(xy_a[1].to_i)
          self.errors.add(:say, 'block xy range')
          error_flag = true
        end
      else
        self.errors.add(:say, 'block xy size')
        error_flag = true
      end

      text_count = 0
      text.each_char do |char|
        text_count += (char.size > 1 && char !~ /[｡-ﾟ]/u ? 2 : 1)
      end
      if text_count > 10
        self.errors.add(:say, "block text size")
        error_flag = true
      end
      
      break if error_flag
    end
  end

  def say=(_say)
    unless _say.is_a?(Hash)
      super({})
      return
    end
    
    tmp = {}
    if _say[:message].present?
      tmp[:message] = _say[:message]
    end
    if _say[:block].is_a?(Hash)
      tmp[:block] = {}
      block_range = Array(Game::BlockRange).join
      _say[:block].map do |k,v|
        if k =~ /\A[#{block_range}]_[#{block_range}]\Z/ && v.present?
          tmp[:block][k] = v
        end
      end
      tmp.delete(:block) if tmp[:block].blank?
    end
    
    super(tmp)
  end

  def say_message
    self.say.present? ? self.say[:message] : nil
  end
  def say_block
    self.say.present? && self.say[:block].is_a?(Hash) ?
      self.say[:block] : {}
  end

  def same_turn_count
    self.class.game_and_turn(self.game_id, self.user_id, self.turn).count
  end

end
