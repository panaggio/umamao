class Report
  attr_reader :group, :since
  attr_reader :questions, :answers, :users, :votes

  def initialize(group, since = Time.now.yesterday)
    @group = group
    @since = since

    @questions = group.questions.count(:created_at => {:$gt => since})
    @answers = group.answers.count(:created_at => {:$gt => since})

    @users = User.count("membership_list.#{group.id}.reputation" => {:$exists => true})

    @votes = group.votes.count(:created_at => {:$gt => since})
  end
end
