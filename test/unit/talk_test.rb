require 'test_helper'

class TalkTest < ActiveSupport::TestCase
  context "basic" do
    should belong_to(:user)
    should belong_to(:game)
    [:user, :game, :say, :turn].map do |attr|
      should validate_presence_of(attr)
    end
    should validate_numericality_of(:turn)

    should "validate_user_eq_game_user" do
      _talk = Factory(:talk)
      assert _talk.valid?

      _talk.user = Factory(:user)
      assert !_talk.valid?
      assert _talk.errors[:user].present?
    end

    should "validate_turn_count" do
      _talk = Factory(:talk)
      _game = _talk.game
      2.times do
        _talk = Factory(:talk, :game => _game, :user => _talk.user)
      end
      _talk = Factory.build(:talk, :game => _game, :user => _talk.user)
      assert !_talk.valid?
      assert _talk.errors[:turn].present?
    end

    context "say" do
      should "validate_say_message" do
        _talk = Factory(:talk)
        [
          ["a" * 500, true],
          ["a" * 501, false],
        ].map do |text, flag|
          _talk.say = {
            :message => text
          }
          assert_equal _talk.valid?, flag
        end
      end

      should "validate_say_block_text" do
        _talk = Factory(:talk)
        _talk.say[:block] = {'1_1_1' => "aaa"}
        assert !_talk.valid?
        assert_equal _talk.errors[:say].first, 'block xy size'

        _talk.say[:block] = {'1_4' => "aaa"}
        assert !_talk.valid?
        assert_equal _talk.errors[:say].first, 'block xy range'

        [
          ["aaaaaaaaaa", true],
          ["aaaaaaaaaaa", false]
        ].map do |text, flag|
          _talk.say[:block] = {'1_1' => text}
          assert_equal _talk.valid?, flag
          assert_equal _talk.errors[:say].first, 'block text size' unless flag
        end
      end
    end
  end
end
