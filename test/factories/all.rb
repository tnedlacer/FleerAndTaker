Factory.define(:user) do |u|
  u.twitter_id { Factory.next(:twitter_id) }
  u.login { Factory.next(:twitter_login) }
  u.access_token 'fakeaccesstoken'
  u.access_secret 'fakeaccesstokensecret'
  u.profile_image_url 'test.gif'
  u.name 'Twitter Man'
  u.description 'Saving the world for all Twitter kind.'
end
Factory.define(:twitter_oauth_user, :parent => :user) do |u|
end

Factory.sequence :twitter_id do |n|
  n + User.count * 100
end
Factory.sequence :twitter_login do |n|
  "twitterman#{n + User.count * 100}"
end

Factory.define :game do |g|
  g.fleer {Factory(:twitter_oauth_user)}
  g.taker {Factory(:twitter_oauth_user)}
  g.app_data Game.dump_app_data({:key_x => 1, :key_y => 2})
  g.finish 0
  g.moves {[
      Factory(:fleer_move, :turn => 1, :rival_x => 3, :rival_y => 3),
      Factory(:taker_move, :turn => 1, :to_x => 3, :to_y => 3, :rival_x => 1, :rival_y => 1),
      Factory(:fleer_move, :turn => 2, :to_x => 1, :to_y => 1, :rival_x => 1, :rival_y => 3, :key_x => 1, :key_y => 2),
      Factory(:taker_move, :turn => 2, :to_x => 3, :to_y => 3, :rival_x => 1, :rival_y => 1, :key_x => 3, :key_y => 2),
    ]}
  g.after_build do |gg|
    gg.host = gg.fleer
  end
end

Factory.define :move do |m|
  m.turn 1
  m.fleer_or_taker 1
  m.to_x 1
  m.to_y 1
  m.key_x 1
  m.key_y 1
  m.rival_x 1
  m.rival_y 1
end

Factory.define(:fleer_move, :parent => :move) do |m|
  m.fleer_or_taker 1
  m.key_x 1
  m.key_y 1
end
Factory.define(:taker_move, :parent => :move) do |m|
  m.fleer_or_taker 2
  m.key_x 3
  m.key_y 3
end

Factory.define(:talk_common, :class => :talk) do |t|
  t.game {Factory(:game)}
  t.turn 1
  t.say({:message => Array.new(rand(20)){(Array('a'..'z') + Array('A'..'Z') + Array('0'..'9'))[rand(62)]}.join})
end
Factory.define(:talk, :parent => :talk_common) do |t|
  t.after_build do |tt|
    tt.user = tt.game.taker
  end
end
Factory.define(:fleer_talk, :parent => :talk_common) do |t|
  t.after_build do |tt|
    tt.user = tt.game.fleer
  end
end
