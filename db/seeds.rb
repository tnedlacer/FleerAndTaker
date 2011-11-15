# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Daley', :city => cities.first)

u = User.new(:name => 'CPU', :login => 'CPU', :profile_image_url => '/images/cpu.gif')
u.twitter_id = 0
u.id = 0
u.save

