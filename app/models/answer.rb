class Answer < Comment
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include Support::Versionable
  key :_id, String

  key :body, String, :required => true
  key :language, String, :default => 'pt-BR'
  key :flags_count, Integer, :default => 0
  key :banned, Boolean, :default => false
  key :wiki, Boolean, :default => false

  timestamps!

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :question_id, String
  belongs_to :question

  has_many :flags, :as => "flaggeable", :dependent => :destroy

  has_many :comments, :foreign_key => "commentable_id", :class_name => "Comment", :order => "created_at asc", :dependent => :destroy

  # This ought to be has_one, but it wasn't working
  has_many :news_updates, :as => "entry", :dependent => :destroy

  validates_presence_of :user_id
  validates_presence_of :question_id

  versionable_keys :body
  filterable_keys :body

  validate :disallow_spam
  validate :check_unique_answer, :if => lambda { |a| (!a.group.forum && !a.disable_limits?) }

  after_create :create_news_update, :new_answer_notification

  def title
    self.question.title
  end

  def topics
    self.question.topics
  end

  def check_unique_answer
    check_answer = Answer.first(:question_id => self.question_id,
                               :user_id => self.user_id)

    if !check_answer.nil? && check_answer.id != self.id
      self.errors.add(:limitation, "Your can only post one answer per question.")
      return false
    end
  end

  def update_question_answered_with
    # Update question 'answered' status
    if !self.question.answered && self.votes_average >= 1
      Question.set(self.question.id, {:answered_with_id => self.id})
    elsif self.question.answered_with_id == self.id && self.votes_average < 1
      other_good_answer = self.question.answers.detect { |answer|
        answer.votes_average >= 1
      }

      answered_with_id = other_good_answer ? other_good_answer.id : nil

      Question.set(self.question.id, {:answered_with_id => answered_with_id})
    end
  end

  def on_add_vote(v, voter)
    if v > 0
      self.user.update_reputation(:answer_receives_up_vote, self.group)
      voter.on_activity(:vote_up_answer, self.group)
    else
      self.user.update_reputation(:answer_receives_down_vote, self.group)
      voter.on_activity(:vote_down_answer, self.group)
    end

    update_question_answered_with
  end

  def on_remove_vote(v, voter)
    if v > 0
      self.user.update_reputation(:answer_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_answer, self.group)
    else
      self.user.update_reputation(:answer_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_answer, self.group)
    end

    update_question_answered_with
  end

  def flagged!
    self.collection.update({:_id => self._id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end

  def ban
    self.question.answer_removed!
    self.set({:banned => true})
  end

  def self.ban(ids)
    self.find_each(:_id.in => ids, :select => [:question_id]) do |answer|
      answer.ban
    end
  end

  def to_html
    Maruku.new(self.body).to_html
  end

  def disable_limits?
    self.user.present? && self.user.can_post_whithout_limits_on?(self.group)
  end

  def disallow_spam
    if new? && !disable_limits?
      eq_answer = Answer.first({:body => self.body,
                                  :question_id => self.question_id,
                                  :group_id => self.group_id
                                })

      last_answer  = Answer.first(:user_id => self.user_id,
                                   :question_id => self.question_id,
                                   :group_id => self.group_id,
                                   :order => "created_at desc")

      valid = (eq_answer.nil? || eq_answer.id == self.id) &&
              ((last_answer.nil?) || (Time.now - last_answer.created_at) > 20)
      if !valid
        self.errors.add(:body, "Your answer looks like spam.")
      end
    end
  end

  def create_news_update
    NewsUpdate.create(:author => self.user, :entry => self,
                      :created_at => self.created_at, :action => 'created')
  end
  
  def new_answer_notification
	# only if the answer inst created by question creator and question creator asked to receive
	#email notification about answers
    if self.question.user != self.user && self.question.user.notification_opts.new_answer
		Notifier.new_answer(self.question.user, self.group, self, false).deliver
	end
  end

  # Returns the (only) associated news update.
  # We need this because has_one doesn't work.
  def news_update
    news_updates.first
  end

end
