require 'test_helper'

class QuestionTest < ActiveSupport::TestCase
  def setup
    Group.delete_all
    Question.delete_all
    User.delete_all
  end

  test "should be deletable only by admins" do
    u = Factory.create(:user)
    q = Factory.create(:question, :user => u)
    a = Factory.create(:admin)

    assert !q.can_be_deleted_by?(u)
    assert q.can_be_deleted_by?(a)
    assert !q.can_be_deleted_by?(nil)
  end
end
