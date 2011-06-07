require 'test_helper'

class UserTest < ActiveSupport::TestCase
  def setup
    User.delete_all
    WaitingUser.delete_all
    Topic.delete_all
    Affiliation.delete_all
  end

  test "should not save a user with empty name" do
    u = Factory.build(:user, :name => '')
    assert !u.save, "Saved user with empty name"

    assert_raise(MongoMapper::DocumentNotValid){ u.save! }
  end

  test "should not save a user with nil name" do
    u = Factory.build(:user, :name => nil)
    assert !u.save, "Saved user with nil name"

    assert_raise(MongoMapper::DocumentNotValid){ u.save! }
  end

  test "should associate to waiting user through email" do
    wu = Factory.create(:waiting_user)
    u = Factory.create(:user, :email => wu.email)
    wu.reload
    assert_equal u, wu.user
  end

  test "should associate to waiting user through affiliation" do
    a = Factory.build :affiliation
    wu = Factory.create :waiting_user, :email => a.email
    a.save
    u = Factory.create :affiliated_user, :affiliations => [a]
    wu.reload

    assert_equal u, wu.user
  end
end
