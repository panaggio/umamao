# -*- coding: utf-8 -*-
require 'spec_helper'

# Hideous code. Please fix this with proper fixtures and matchers.
describe NewsUpdate do
  Question.delete_all
  NewsUpdate.delete_all
  NewsItem.delete_all
  User.delete_all
  Group.delete_all

  user = User.new({:name => 'João da Silva', :password => 'test1234',
                        :password_confirmation => 'test1234',
                        :email => 'joao@example.com',
                        :academic_email => 'example@unicamp.br'})
  user.save(:validate => false)

  user1 = User.new({:name => 'João1 da Silva', :password => 'test1234',
                        :password_confirmation => 'test1234',
                        :email => 'joao1@example.com',
                        :academic_email => 'example1@unicamp.br'})
  user1.save(:validate => false)

  user2 = User.new({:name => 'João2 da Silva', :password => 'test1234',
                        :password_confirmation => 'test1234',
                        :email => 'joao2@example.com',
                        :academic_email => 'example2@unicamp.br'})
  user2.save(:validate => false)

  group = Group.new(:name => 'default_group',
                    :subdomain => 'default',
                    :domain => AppConfig.domain,
                    :description => "question-and-answer website",
                    :legend => "question and answer website",
                    :default_tags => %w[tag1 tag2],
                    :state => "active")
  group.owner = user
  group.save!
  group.add_member(user, "owner")

  question = Question.create!(:title => 'What is X?', :user => user, :group => group)

  users = User.all - [user]
  users.each { |u| u.add_friend(user) }

  news_update = NewsUpdate.create!(:author => user, :entry => question,
                                   :action => 'created')

  NewsItem.from_news_update!(news_update)

  puts users.map{ |u| u.news_items.size == 1 }.inspect
  puts user.news_items.size == 0
end
