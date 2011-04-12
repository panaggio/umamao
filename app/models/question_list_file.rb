# Uploaded files that correspond to a list of questions

class QuestionListFile < UploadedFile
  belongs_to :question_list

  def can_be_destroyed_by?(user)
    super || self.question_list.user == user
  end

end
