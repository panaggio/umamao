require 'test_helper'

class UserTopicInfoTest < ActiveSupport::TestCase
  DELTA = 10.seconds

  def setup
    User.find_each(&:destroy)
    Topic.find_each(&:destroy)
    UserTopicInfo.find_each(&:destroy)
  end

  test "should not create a new user_topic_info with nil user" do
    assert_raise(MongoMapper::DocumentNotValid){
      Factory.create(:user_topic_info, :user => nil)
    }
  end

  test "should not create a new user_topic_info with nil topic" do
    assert_raise(MongoMapper::DocumentNotValid){
      Factory.create(:user_topic_info, :topic => nil)
    }
  end

  test "should not create a duplicate user_topic_info" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    Factory.create(:user_topic_info, :user => u, :topic => t)
    assert_raise(MongoMapper::DocumentNotValid){
      Factory.create(:user_topic_info, :user => u, :topic => t)
    }
  end

  test "should check if user follows topic properly" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    t.add_follower!(u)
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_equal u.following?(t), ut.followed?
  end

  test "should keep the correct date of follow on follow topic" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    t.add_follower!(u)
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_in_delta(ut.followed_at, Time.now, DELTA)
  end

  test "should check if user ignores topic property" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    u.ignore_topic!(t)
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_equal u.ignores?(t), ut.ignored?
  end

  test "should keep the correct date of ignore on ignore topic" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    u.ignore_topic!(t)
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_in_delta(ut.ignored_at, Time.now, DELTA)
  end
end

