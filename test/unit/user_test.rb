require 'test_helper'
 
class UserTest < ActiveSupport::TestCase
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
end
