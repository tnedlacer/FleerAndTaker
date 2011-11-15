require 'test_helper'

class MoveTest < ActiveSupport::TestCase
  context "basic" do
    should belong_to(:game)

    [:key_x, :key_y, :rival_x, :rival_y].map do |attr|
      should validate_numericality_of(attr)
      should_not validate_presence_of(attr).with_message(/not a number/)
    end
    [:turn, :to_x, :to_y].map do |attr|
      should validate_numericality_of(attr)
      should validate_presence_of(attr)
    end
    should ensure_inclusion_of(:fleer_or_taker).in_range([1,2])

    [:key_x, :key_y, :rival_x, :rival_y, :turn, :to_x, :to_y].map do |attr|
      should_not allow_value(0).for(attr)
    end

    should "xy" do
      move1 = Factory(:move)
      [:to, :key, :rival].map do |attr_pre|
        move1.__send__("#{attr_pre}_xy=", [1,2])
        assert_equal move1.__send__("#{attr_pre}_x"), 1
        assert_equal move1.__send__("#{attr_pre}_y"), 2
      end
    end
  end
end
