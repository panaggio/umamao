# -*- coding: utf-8 -*-
class Question
  include MongoMapper::Document
  include MongoMapperExt::Filter
  include MongoMapperExt::Slugizer
  include MongoMapperExt::Tags
  include Support::Versionable
  include Support::Voteable
  include Scopes

  ensure_index :tags
  ensure_index :language

  key :_id, String
  key :title, String, :required => true
  key :body, String
  slug_key :title, :unique => true, :min_length => 8
  key :slugs, Array, :index => true
  key :autocomplete_keywords, Array, :index => true

  key :topic_ids, Array, :index => true
  many :topics, :in => :topic_ids

  key :answers_count, Integer, :default => 0
  key :views_count, Integer, :default => 0
  key :hotness, Integer, :default => 0
  key :flags_count, Integer, :default => 0
  key :favorites_count, Integer, :default => 0

  key :adult_content, Boolean, :default => false
  key :banned, Boolean, :default => false
  key :accepted, Boolean, :default => false
  key :closed, Boolean, :default => false
  key :closed_at, Time

  key :exercise, Boolean, :default => false, :index => true

  key :parent_question_id, String, :index => true
  belongs_to :parent_question, :class_name => 'Question'
  scope :children_of, lambda { |question|
    where(:parent_question_id => question.id)
  }

  key :answered_with_id, String
  belongs_to :answered_with, :class_name => "Answer"

  key :wiki, Boolean, :default => false
  key :language, String, :default => 'pt-BR'

  key :activity_at, Time

  key :user_id, String, :index => true
  belongs_to :user

  key :answer_id, String
  belongs_to :answer

  key :group_id, String, :index => true
  belongs_to :group

  key :watchers, Array

  key :updated_by_id, String
  belongs_to :updated_by, :class_name => "User"

  key :close_reason_id, String

  key :last_target_type, String
  key :last_target_id, String
  key :last_target_date, Time

  belongs_to :last_target, :polymorphic => true

  has_many :answers, :dependent => :destroy
  has_many :flags, :as => "flaggeable", :dependent => :destroy
  has_many :comments, :as => "commentable", :order => "created_at asc", :dependent => :destroy
  has_many :close_requests

  # This ought to be has_one, but it wasn't working
  has_many :news_updates, :as => "entry", :dependent => :destroy

  validates_presence_of :user_id
  validates_uniqueness_of :slug, :scope => :group_id, :allow_blank => true

  validates_length_of :title, :within => 5..280, :message =>
    lambda {
      if title.length < 5
        I18n.t("questions.model.messages.title_too_short")
      else
        I18n.t("questions.model.messages.title_too_long")
      end
    }

  validates_length_of :body, :minimum => 5, :allow_blank => true,
    :allow_nil => true,
    :message => lambda { I18n.t("questions.model.messages.body_too_short") }

  validates_true_for :tags, :logic => lambda { tags.size <= 9 },
    :message => lambda {
                  if tags.size > 9
                    I18n.t("questions.model.messages.too_many_tags")
                  end
                }

  versionable_keys :title, :body, :tags, :topics
  filterable_keys :title, :body
  language :language

  before_save :update_activity_at, :update_exercise
  before_save :update_autocomplete_keywords
  before_create :add_question_author_to_watchers
  before_create :get_topics_from_parent
  after_create :create_news_update

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES
  validates_true_for :language, :logic => lambda { |q| q.group.language == q.language },
                                :if => lambda { |q| !q.group.language.nil? }
  validate :disallow_spam
  validate :check_useful

  timestamps!

  # TODO: remove this
  def tags=(t)
    if t.kind_of?(String)
      t = t.downcase.split(",").join(" ").split(" ").uniq
    end

    self[:tags] = t
  end

  def self.related_questions(question, opts = {})
    opts[:per_page] ||= 10
    opts[:page]     ||= 1
    opts[:group_id] = question.group_id
    opts[:banned] = false

    Question.paginate(opts.merge(:topic_ids => question.topic_ids,
                                 :_id => {:$ne => question.id}))
  end

  def viewed!(ip)
    view_count_id = "#{self.id}-#{ip}"
    if ViewsCount.find(view_count_id).nil?
      ViewsCount.create(:_id => view_count_id)
      self.collection.update({:_id => self._id}, {:$inc => {:views_count => 1}},
                                                :upsert => true)
    end
  end

  def answer_added!
    self.collection.update({:_id => self._id}, {:$inc => {:answers_count => 1}},
                                              :upsert => true)
    on_activity
  end

  def answer_removed!
    self.collection.update({:_id => self._id}, {:$inc => {:answers_count => -1}},
                                               :upsert => true)
  end

  def flagged!
    self.collection.update({:_id => self._id}, {:$inc => {:flags_count => 1}},
                                               :upsert => true)
  end

  def on_add_vote(v, voter)
    if v > 0
      self.user.update_reputation(:question_receives_up_vote, self.group)
      voter.on_activity(:vote_up_question, self.group)
    else
      self.user.update_reputation(:question_receives_down_vote, self.group)
      voter.on_activity(:vote_down_question, self.group)
    end
    on_activity(false)
  end

  def on_remove_vote(v, voter)
    if v > 0
      self.user.update_reputation(:question_undo_up_vote, self.group)
      voter.on_activity(:undo_vote_up_question, self.group)
    else
      self.user.update_reputation(:question_undo_down_vote, self.group)
      voter.on_activity(:undo_vote_down_question, self.group)
    end
    on_activity(false)
  end

  def add_favorite!(fav, user)
    self.collection.update({:_id => self._id}, {:$inc => {:favorites_count => 1}},
                                                          :upsert => true)
    on_activity(false)
  end


  def remove_favorite!(fav, user)
    self.collection.update({:_id => self._id}, {:$inc => {:favorites_count => -1}},
                                                          :upsert => true)
    on_activity(false)
  end

  def on_activity(bring_to_front = true)
    update_activity_at if bring_to_front
    self.collection.update({:_id => self._id}, {:$inc => {:hotness => 1}},
                                                         :upsert => true)
  end

  # FIXME: Is this still working?
  def update_exercise
    self.exercise = self.tags.include?('resolução-de-exercício')
  end

  def update_activity_at
    now = Time.now
    if new?
      self.activity_at = now
    else
      self.collection.update({:_id => self._id}, {:$set => {:activity_at => now}},
                                                 :upsert => true)
    end
  end

  def ban
    self.collection.update({:_id => self._id}, {:$set => {:banned => true}},
                                               :upsert => true)
    topics.each do |topic|
      topic.increment(:questions_count => -1)
    end
  end

  def self.ban(ids)
    ids = ids.map do |id| id end

    self.collection.update({:_id => {:$in => ids}}, {:$set => {:banned => true}},
                                                     :multi => true,
                                                     :upsert => true)
    query(:id.in => ids, :select => :topic_ids).each do |question|
      question.topics.each do |topic|
        topic.increment(:questions_count => -1)
      end
    end
  end

  def unban
    self.collection.update({:_id => self._id}, {:$set => {:banned => false}},
                                               :upsert => true)
    topics.each do |topic|
      topic.increment(:questions_count => 1)
    end
  end

  def self.unban(ids)
    ids = ids.map do |id| id end

    self.collection.update({:_id => {:$in => ids}}, {:$set => {:banned => false}},
                                                     :multi => true,
                                                     :upsert => true)
    query(:id.in => ids, :select => :topic_ids).each do |question|
      question.topics.each do |topic|
        topic.increment(:questions_count => 1)
      end
    end

  end

  def favorite_for?(user)
    user.favorite(self)
  end


  def add_watcher(user)
    if !watch_for?(user)
      self.collection.update({:_id => self.id},
                             {:$push => {:watchers => user.id}},
                             :upsert => true);
    end
  end

  def remove_watcher(user)
    if watch_for?(user)
      self.collection.update({:_id => self.id},
                             {:$pull => {:watchers => user._id}},
                             :upsert => true)
    end
  end

  def watch_for?(user)
    watchers.include?(user._id)
  end

  def disable_limits?
    self.user.present? && self.user.can_post_whithout_limits_on?(self.group)
  end

  def check_useful
    unless disable_limits?
      if !self.title.blank? && self.title.gsub(/[^\x00-\x7F]/, "").size < 5
        return
      end

      if !self.title.blank? && (self.title.split.count < 4)
        self.errors.add(:title, I18n.t("questions.model.messages.too_short", :count => 4))
      end

      if !self.body.blank? && (self.body.split.count < 4)
        self.errors.add(:body, I18n.t("questions.model.messages.too_short", :count => 3))
      end
    end
  end

  def disallow_spam
    if new? && !disable_limits?
      last_question = Question.first( :user_id => self.user_id,
                                      :group_id => self.group_id,
                                      :order => "created_at desc")

      valid = (last_question.nil? || (Time.now - last_question.created_at) > 20)
      if !valid
        self.errors.add(:body, "Your question looks like spam. you need to wait 20 senconds before posting another question.")
      end
    end
  end

  def answered
    self.answered_with_id.present?
  end

  def self.update_last_target(question_id, target)
    self.collection.update({:_id => question_id},
                           {:$set => {:last_target_id => target.id,
                                      :last_target_type => target.class.to_s,
                                      :last_target_date => target.updated_at.utc}},
                           :upsert => true)
  end

  def can_be_requested_to_close_by?(user)
    ((self.user_id == user.id) && user.can_vote_to_close_own_question_on?(self.group)) ||
    user.can_vote_to_close_any_question_on?(self.group)
  end

  def can_be_deleted_by?(user)
    (self.user_id == user.id) || (self.closed && user.can_delete_closed_questions_on?(self.group))
  end

  def close_reason
    self.close_requests.detect{ |rq| rq.id == close_reason_id }
  end

  # Returns the (only) associated news update.
  # We need this because has_one isn't working.
  def news_update
    news_updates.first
  end

  # Classifies self under topic topic.
  def classify!(topic)
    if !topic_ids.include? topic.id
      topics << topic

      # Notify followers of new topic and the topic itself. We give
      # them the current timestamp so they will appear on top of the
      # news feed.

      # We need this to make sure that answers appear after question.
      stamp = Time.zone.now

      # Question updates
      if news_update
        # Users
        topic.followers.each do |follower|
          if NewsItem.query(:recipient_id => follower.id,
                            :recipient_type => "User",
                            :news_update_id => news_update.id).count == 0
            NewsItem.notify!(news_update, follower, topic, stamp)
          end
        end
        # Topic
        if NewsItem.query(:recipient_id => topic.id,
                          :recipient_type => "Topic",
                          :news_update_id => news_update.id).count == 0
          NewsItem.notify!(news_update, topic, topic, stamp)
        end
      end

      if !banned
        topic.increment(:questions_count => 1)
      end

      save
    else
      false
    end
  end

  # Removes self from topic topic.
  def unclassify!(topic)
    if topic_ids.include? topic.id
      topic_ids.delete topic.id
      if !banned
        topic.increment(:questions_count => -1)
      end

      # Remove related news items
      if self.news_update
        NewsItem.query(:origin_id => topic.id,
                       :origin_type => "Topic",
                       :news_update_id => self.news_update.id).each &:delete
      end

      self.answers.each do |answer|
        if answer.news_update
          news_items = NewsItem.query(:origin_id => topic.id,
                                      :origin_type => "Topic",
                                      :news_update_id => answer.news_update.id)
          news_items.each(&:delete)
        end
      end

      save
    else
      false
    end
  end

  def create_news_update
    NewsUpdate.create(:author => self.user, :entry => self,
                      :created_at => created_at, :action => 'created')
  end

  protected
  def update_answer_count
    self.answers_count = self.answers.where(:banned => false).count
    votes_average = 0
    self.votes.each {|e| votes_average+=e.value }
    self.votes_average = votes_average

    self.votes_count = self.votes.count
  end

  def update_autocomplete_keywords
    if !title.nil?
      @autocomplete_keywords = title.split(/\W/).
        delete_if {|w| w.empty?}.map &:downcase
    end
  end

  def get_topics_from_parent
	#debugger
	self.topics = self.parent_question.topics if self.parent_question_id.present?

	#self.topics = (self.parent_question_id != "" ? self.parent_question.topics : Array.new)
  end

  def add_question_author_to_watchers
    self.watchers = [self.user_id]
  end

end

