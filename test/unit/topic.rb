require 'test_helper'
 
class TopicTest < ActiveSupport::TestCase
  test "should not save with empty title" do
    assert_raise(MongoMapper::DocumentNotValid){
      Factory.create(:topic, :title => '')
    }
  end

  test "should not save with nil title" do
    assert_raise(MongoMapper::DocumentNotValid){
      Factory.create(:topic, :title => nil)
    }
  end

  test 'should save a topic with title properly' do
    assert Factory.create(:topic)
  end

  test 'should save two topics with different titles' do
    assert Factory.create(:topic)
    assert Factory.create(:topic)
  end

  test 'should not save a topic with duplicate title' do
    Factory.create(:topic, :title => 'Title')
    assert_raise(MongoMapper::DocumentNotValid){
      Factory.create(:topic, :title => 'Title')
    }
  end
end
