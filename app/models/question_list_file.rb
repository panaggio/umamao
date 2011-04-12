# Uploaded files that correspond to a list of questions

class QuestionListFile < UploadedFile
  belongs_to :question_list
end
