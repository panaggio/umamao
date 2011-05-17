require 'test_helper'

class QuestionListTest < ActiveSupport::TestCase

  def setup
    Group.delete_all
    Topic.delete_all
    QuestionList.delete_all
    Question.delete_all
    User.delete_all
    Delayed::Job.delete_all

    @main_topic = Factory.create(:topic)
    @topic = Factory.create(:topic)
  end

  test "should classify questions after topic is included" do
    question_list = Factory.create(:question_list, :main_topic => @main_topic)
    question = Factory.create(:question)
    question.classify!(question_list)
    question_list.classify!(@topic)
    assert(question.reload.topics.include?(@topic))
  end

  test "should unclassify questions after topic is removed" do
    question_list = Factory.create(:question_list, :main_topic => @main_topic)
    question = Factory.create(:question, :topics => [@topic, question_list])
    question_list.classify!(@topic)
    question_list.unclassify!(@topic)
    assert(!question.reload.topics.include?(@topic))
  end

end


