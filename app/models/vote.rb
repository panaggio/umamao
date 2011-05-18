class Vote
  include MongoMapper::Document

  timestamps!

  key :_id, String
  key :value, Integer, :required => true

  key :user_id, String, :index => true
  belongs_to :user

  key :user_ip, String

  key :group_id, String, :required => true, :index => true
  belongs_to :group

  key :voteable_id, String
  key :voteable_type, String
  belongs_to :voteable, :polymorphic => true

  validates_presence_of :user_id, :voteable_id, :voteable_type
  validates_inclusion_of :value, :within => [1,-1]

  ensure_index([[:user_id, 1], [:voteable_id, 1], [:voteable_type, 1]],
               :unique => true)

  validate :check_reputation
  validate :check_owner
  validate :check_voteable

  before_validation :add_to_group
  before_validation :check_previous_vote

  after_create :add_to_voteable
  after_create :set_creation_status

  after_destroy :remove_from_voteable

  # FIXME: This attribute tracks whether creating this vote changed
  # previous votes' states or not. This is only used so we can move
  # the logic from the controller into the model without changing the
  # controller and views too much.
  attr_accessor :creation_status

  def valid?
    super && creation_status != :deleted
  end

  protected
  def check_reputation
    if self.value > 0
      unless user.can_vote_up_on?(self.voteable.group)
        reputation = self.voteable.group.reputation_constrains["vote_up"]
        self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                            :min_reputation => reputation,
                                            :action => I18n.t("users.actions.vote_up")))
        return false
      end
    else
      unless user.can_vote_down_on?(self.voteable.group)
        reputation = self.voteable.group.reputation_constrains["vote_down"]
        self.errors.add(:reputation, I18n.t("users.messages.errors.reputation_needed",
                                            :min_reputation => reputation,
                                            :action => I18n.t("users.actions.vote_down")))
        return false
      end
    end
    return true
  end

  def check_owner
    if self.voteable.user == self.user
      error = I18n.t(:flash_error, :scope => "votes.create") + " "
      error += I18n.t(self.voteable_type.downcase, :scope => "activerecord.models").downcase
      self.errors.add(:user, error)
      return false
    end
    return true
  end

  def check_voteable
    valid = true
    error_message = ""
    case self.voteable_type
    when "Question"
      valid = !self.voteable.closed
      error_message = I18n.t("votes.model.messages.closed_question")
    when "Answer"
      valid = !self.voteable.question.closed
      error_message = I18n.t("votes.model.messages.closed_question")
    when "Comment"
      valid = self.value > 0
      unless valid
        error_message = I18n.t("votes.model.messages.vote_down_comment")
      else
        case self.voteable.commentable_type
        when "Question"
          valid = !self.voteable.commentable.closed
          error_message = I18n.t("votes.model.messages.closed_question")
        when "Answer"
          valid = !self.voteable.commentable.question.closed
          error_message = I18n.t("votes.model.messages.closed_question")
        end
      end
    end
    if !valid
      self.errors.add(self.voteable_type.tableize.singularize, error_message)
    end
    return valid
  end

  # Include the vote on the group of the voted entity.
  def add_to_group
    self.group = self.voteable.group
  end

  def check_previous_vote
    user_vote = self.user.vote_on(self.voteable)

    return if user_vote.nil?

    user_vote.destroy
    self.creation_status =
      if user_vote.value == self.value
        :deleted
      elsif self.value == 1
        :changed_downvote_to_upvote
      else
        :changed_upvote_to_downvote
      end

  end

  def add_to_voteable
    voteable.add_vote!(value, user)
  end

  def set_creation_status
    creation_status ||= :created
  end

  # Ensures the vote is removed from the voted entity.
  def remove_from_voteable
    voteable.remove_vote!(value, user) if voteable
  end

end
