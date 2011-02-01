# -*- coding: utf-8 -*-
require 'faker'

Factory.sequence(:email) { |n|
  "r#{n}@example.com"
}

FactoryGirl.define do
  factory :user do
    name Faker::Name.name
    password 'test1234'
    password_confirmation 'test1234'
    email
  end
end
