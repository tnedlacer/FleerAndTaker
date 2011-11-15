class Move < ActiveRecord::Base

  belongs_to :game

  validates :game, :presence => true, :unless => proc{|m|m.game_id.blank?}
  validates_inclusion_of :fleer_or_taker, :in => [1,2], :presence => true
  validates :turn, :to_x, :to_y, :presence => true
  validates_uniqueness_of :turn, :scope => [:game_id, :fleer_or_taker]
  validates_numericality_of :turn, :to_x, :to_y, :greater_than => 0
  validates_numericality_of :key_x, :key_y, :rival_x, :rival_y, :greater_than => 0, :allow_blank => true

  validate :check_fleer_and_taker_trun
  
  after_save :call_set_finished

  [:to, :key, :rival].map do |attr_pre|
    define_method("#{attr_pre}_xy") do
      [self.__send__("#{attr_pre}_x"), self.__send__("#{attr_pre}_y")]
    end
    define_method("#{attr_pre}_xy=") do |xy|
      self.__send__("#{attr_pre}_x=", xy[0])
      self.__send__("#{attr_pre}_y=", xy[1])
      self.__send__("#{attr_pre}_xy")
    end
  end

  def check_fleer_and_taker_trun
    return true if self.game.blank?
    self.game.try("#{self.fleer_or_taker == 1 ? :taker : :fleer}_turn", true) >= self.turn
  end

  protected
    def call_set_finished
      return true if self.game.blank?
      self.game.set_finished
      true
    end
  public

end
