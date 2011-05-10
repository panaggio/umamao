require 'test_helper'
 
class UserTopicInfoTest < ActiveSupport::TestCase
  test "should not save with nil user" do
    ut = Factory.build(:user_topic_info, :user => nil)
    assert !ut.save

    assert_raise(MongoMapper::DocumentNotValid){ ut.save! }
  end

  test "should not save with nil topic" do
    ut = Factory.build(:user_topic_info, :topic => nil)
    assert !ut.save

    assert_raise(MongoMapper::DocumentNotValid){ ut.save! }
  end
end

