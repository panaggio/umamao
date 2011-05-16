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
    @topic1 = Factory.create(:topic)
    @topic2 = Factory.create(:topic)
  end

  test "should classify questions after topic is included" do
    question_list = Factory.create(:question_list, :main_topic => @main_topic)
    question = Factory.create(:question)
    question.classify!(question_list)
    question_list.classify!(@topic1)
    assert(question.topics.include?(@topic1))
  end

end


