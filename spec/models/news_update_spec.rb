# -*- coding: utf-8 -*-
require 'spec_helper'
require 'factories/user'
require 'factories/group'

# Hideous code. Please fix this with proper fixtures and matchers.
describe NewsUpdate do
  Question.delete_all
  NewsUpdate.delete_all
  NewsItem.delete_all
  User.delete_all
  Group.delete_all

  user1 = Factory(:user)
  user2 = Factory(:user)
  user3 = Factory(:user)
  group = Factory(:group)

  question = Question.create!(:title => 'What does X mean?', :user => user1,
                              :group => group)

  users = User.all - [user1]
  users.each { |u| u.add_friend(user1) }

  news_update = NewsUpdate.create!(:author => user1, :entry => question,
                                   :action => 'created')

  NewsItem.from_news_update!(news_update)

  users.each do |user|
    user.news_items.size.should == 1
  end

  user1.news_items.size.should == 0
end
