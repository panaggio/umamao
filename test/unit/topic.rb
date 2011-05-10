require 'test_helper'
 
class TopicTest < ActiveSupport::TestCase
  test "should not save with empty title" do
    t = Factory.build(:topic, :title => '')
    assert !t.save

    assert_raise(MongoMapper::DocumentNotValid){ t.save! }
  end

  test "should not save with nil title" do
    t = Factory.build(:topic, :title => nil)
    assert !t.save

    assert_raise(MongoMapper::DocumentNotValid){ t.save! }
  end
end
