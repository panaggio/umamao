module Sweepers
  def sweep_question_views
    expire_fragment("tag_cloud_#{current_group.id}")
  end

  def sweep_question(question)
    expire_fragment("question_on_index_#{question.id}_#{question.updated_at}")
    expire_fragment("mini_question_on_index_#{question.id}_#{question.updated_at}")
  end
end
