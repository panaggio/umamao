require 'test_helper'

class UserTopicInfoTest < ActiveSupport::TestCase
  DELTA = 10.seconds

  def setup
    Group.destroy_all
    Question.destroy_all
    UserTopicInfo.destroy_all
    User.destroy_all
    Topic.destroy_all
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

  test "should be able to create two instances for the same user" do
    u = Factory.create(:user)
    t1 = Factory.create(:topic)
    t2 = Factory.create(:topic)

    Factory.create(:user_topic_info, :user => u, :topic => t1)
    assert_nothing_raised{
      Factory.create(:user_topic_info, :user => u, :topic => t2)
    }
  end

  test "should be able to create two instances for the same topic" do
    u1 = Factory.create(:user)
    u2 = Factory.create(:user)
    t = Factory.create(:topic)

    Factory.create(:user_topic_info, :user => u1, :topic => t)
    assert_nothing_raised{
      Factory.create(:user_topic_info, :user => u2, :topic => t)
    }
  end

  test "should check if user follows topic properly" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    ut = Factory.create(:user_topic_info, :user => u, :topic => t)
    ut.follow!

    assert ut.followed?
    assert u.following?(t)
  end

  test "should check if user unfollows topic properly" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    ut = Factory.create(:user_topic_info, :user => u, :topic => t)
    ut.follow!
    ut.unfollow!

    assert !ut.followed?
    assert !u.following?(t)
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
    ut = Factory.create(:user_topic_info, :user => u, :topic => t)
    ut.ignore!

    assert ut.ignored?
    assert u.ignores?(t)
  end

  test "should check if user unignores topic property" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    ut = Factory.create(:user_topic_info, :user => u, :topic => t)
    ut.ignore!
    ut.unignore!

    assert !ut.ignored?
    assert !u.ignores?(t)
  end

  test "should keep the correct date of ignore on ignore topic" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    u.ignore_topic!(t)
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_in_delta(ut.ignored_at, Time.now, DELTA)
  end

  test "questions count should be initially zero" do
    ut = Factory.create(:user_topic_info)
    assert_equal ut.questions_count, 0
  end

  test "should increment questions_count on question add" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    q = Factory.create(:question, :user => u, :topics => [t])
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_equal ut.questions_count, 1
  end

  test "should decrement questions_count on question remove" do
    u = Factory.create(:user)
    t = Factory.create(:topic)
    q = Factory.create(:question, :user => u, :topics => [t])
    UserTopicInfo.question_removed!(q)
    ut = UserTopicInfo.find_by_user_id_and_topic_id(u.id, t.id)

    assert_equal ut.questions_count, 0
  end
end
