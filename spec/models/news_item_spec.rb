# -*- coding: utf-8 -*-
require 'spec_helper'
require 'factories/user'
require 'factories/group'

describe 'NewsItem.from_titles!' do
  context 'when it gets passed a news update from a user with followers' do
    before(:each) do
      Question.delete_all
      NewsUpdate.delete_all
      NewsItem.delete_all
      User.delete_all
      Group.delete_all

      @user1 = Factory(:user)
      @user2 = Factory(:user)
      @user3 = Factory(:user)
      @group = Factory(:group)

      @users = User.all - [@user1]
      @users.each { |u| u.follow(@user1) }

      @question = Question.create!(:title => 'What does X mean?',
                                  :user => @user1, :group => @group)
    end

    it 'should create news items for followers' do
      @users.each do |user|
        user.news_items.size.should == 1
      end
    end

    it 'should create news item for news update author' do
      @user1.news_items.size.should == 1
    end
  end
end
