require 'digest/sha1'

class User
  include MongoMapper::Document
  include Support::Search::Searchable
  include Scopes
  include MongoMapperExt::Filter
  devise :database_authenticatable, :recoverable, :registerable, :rememberable,
         :token_authenticatable, :validatable, :confirmable

  ROLES = %w[user moderator admin]
  LANGUAGE_FILTERS = %w[any user] + AVAILABLE_LANGUAGES
  LOGGED_OUT_LANGUAGE_FILTERS = %w[any] + AVAILABLE_LANGUAGES

  class Helper
    include Singleton
    include GravatarHelper::PublicMethods
    include UsersHelper
  end

  key :_id,                       String
  key :login,                     String, :index => true
  key :name,                      String, :index => true

  key :bio,                       String
  key :website,                   String
  key :location,                  String
  key :birthday,                  Time
  key :gender,                    String, :length => 1, :in => ['m', 'f', nil]
  key :description,               String
  key :new_user,                  Boolean, :default => true

  key :identity_url,              String
  key :role,                      String, :default => "user"
  key :last_logged_at,            Time

  key :preferred_languages,       Array, :default => []

  key :notification_opts,         NotificationConfig

  key :language,                  String, :default => 'pt-BR'
  key :timezone,                  String, :default => "Brasilia"
  key :language_filter,           String, :default => "user", :in => LANGUAGE_FILTERS

  key :ip,                        String

  key :default_subtab,            Hash

  key :followers_count,           Integer, :default => 0
  key :following_count,           Integer, :default => 0

  key :membership_list,           MembershipList

  key :feed_token,                String
  key :can_invite_without_confirmation, Boolean, :default => true

  has_many :affiliations, :dependent => :destroy
  has_many :questions, :dependent => :destroy
  has_many :answers, :dependent => :destroy
  has_many :comments, :dependent => :destroy
  has_many :votes, :dependent => :destroy
  has_many :external_accounts, :dependent => :destroy
  has_many :notifications, :dependent => :destroy

  has_one :suggestion_list, :dependent => :destroy
  delegate :topic_suggestions, :user_suggestions, :suggest,
    :remove_suggestion, :mark_as_uninteresting, :refuse_suggestion,
    :refresh_suggestions, :find_first_suggestions, :to => :suggestion_list

  has_many :favorites, :class_name => "Favorite", :foreign_key => "user_id"

  has_many :news_updates, :foreign_key => :author_id
  has_many :news_items, :as => "recipient", :dependent => :destroy

  key :friend_list_id, String
  belongs_to :friend_list, :dependent => :destroy

  key :invitation_token, String

  attr_accessor :affiliation_token

  # New users should go through our signup wizard to connect their
  # external accounts, receive suggestions, etc.
  key :has_been_through_wizard, Boolean, :default => false

  # Whether or not the user has agreed with our privacy policy and
  # terms of service during signup.
  key :agrees_with_terms_of_service, Boolean, :default => false

  key :last_read_notifications_at, Time

  before_create :create_friend_list, :create_notification_opts
  before_create :generate_uuid

  timestamps!

  before_validation :confirm_from_invitation, :strip_email

  validates_inclusion_of :language, :within => AVAILABLE_LANGUAGES
  validates_inclusion_of :role,  :within => ROLES

  validates_presence_of :name,
    :message => lambda { I18n.t("users.validation.errors.empty_name") }
  validates_length_of :name, :maximum => 100,
    :message => lambda { I18n.t("users.validation.errors.long_name") }
  filterable_keys :name

  validates_length_of       :bio, :maximum => 140,
    :message => lambda { I18n.t("users.validation.errors.long_bio") }
  validates_length_of       :description, :maximum => 500,
    :message => lambda { I18n.t("users.validation.errors.long_description") }

  # We need to be careful with the validation if the user is trying to
  # reset his password. If the user isn't able to login, he won't be
  # able to agree with our ToS, but if he hasn't agreed yet, a naive
  # validation would fail.
  validates_true_for :agrees_with_terms_of_service,
    :logic => lambda {
      (!self.new? && self.password.present? &&
       self.password_confirmation.present?) ||
       self.agrees_with_terms_of_service? },
    :message => lambda { I18n.t("users.validation.errors.did_not_agree") }

  before_create :logged!
  after_create :accept_invitation
  after_create :create_suggestion_list

  scope :confirmed, where(:confirmed_at.ne => nil)
  scope :unconfirmed, where(:confirmed_at => nil)

  def description=(description)
    super(description.try(:strip))
  end

  def self.find_for_authentication(conditions={})
    first(conditions) || first(:login => conditions["email"])
  end

  def self.find_by_login_or_id(login)
    find_by_login(login) || find_by_id(login)
  end

  def self.find_experts(tags, langs = AVAILABLE_LANGUAGES, options = {})
    opts = {}
    opts[:limit] = 15
    opts[:select] = [:user_id]
    if except = options[:except]
      except = [except] unless except.is_a? Array
      opts[:user_id] = {:$nin => except}
    end

    user_ids = UserStat.all(opts.merge({:answer_tags => {:$in => tags}})).map(&:user_id)

    conditions = {"notification_opts.give_advice" => {:$in => ["1", true]},
                  :preferred_languages => langs}

    if group_id = options[:group_id]
      conditions["membership_list.#{group_id}"] = {:$exists => true}
    end

    u = User.find(user_ids, conditions.merge(:select => [:email, :login, :name, :language]))
    u ? u : []
  end

  def confirm_from_invitation
    return if !self.new?
    invitation = Invitation.find_by_invitation_token(self.invitation_token)
    if invitation && invitation.sender.can_invite_without_confirmation?
      self.confirmed_at = Time.now
    end
  end

  # This is used to let people in on sign up. If they're active, they
  # are allowed in, if not, they have to do something (like confirm
  # email) before being allowed to log in.
  def active?
    !self.new? && (self.confirmed_affiliation? || super)
  end

  def confirmed_affiliation?
    self.affiliations.any?(&:confirmed?)
  end

  def first_name
    return nil unless self.name
    self.name.split(/\s+/).first
  end

  def accept_invitation
    invitation = Invitation.find_by_invitation_token(self.invitation_token)
    if invitation
      invitation.accepted_at = Time.now
      invitation.recipient_id = self.id
      invitation.save
    end
  end

  def add_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.collection.update({:_id => self._id, "membership_list.#{group.id}.preferred_tags" =>  {:$nin => t}},
                    {:$pushAll => {"membership_list.#{group.id}.preferred_tags" => t}},
                    {:upsert => true})
  end

  def remove_preferred_tags(t, group)
    if t.kind_of?(String)
      t = t.split(",").join(" ").split(" ")
    end
    self.class.pull_all({:_id => self._id}, {"membership_list.#{group.id}.preferred_tags" => t})
  end

  def preferred_tags_on(group)
    @group_preferred_tags ||= (config_for(group).preferred_tags || []).to_a
  end

  def update_language_filter(filter)
    if LANGUAGE_FILTERS.include? filter
      User.set({:_id => self.id}, {:language_filter => filter})
      true
    else
      false
    end
  end

  def languages_to_filter
    @languages_to_filter ||= begin
      languages = nil
      case self.language_filter
      when "any"
        languages = AVAILABLE_LANGUAGES
      when "user"
        languages = (self.preferred_languages.empty?) ? AVAILABLE_LANGUAGES : self.preferred_languages
      else
        languages = [self.language_filter]
      end
      languages
    end
  end

  def is_preferred_tag?(group, *tags)
    ptags = config_for(group).preferred_tags
    tags.detect { |t| ptags.include?(t) }
  end

  def admin?
    self.role == "admin"
  end

  def age
    return if self.birthday.blank?

    Time.zone.now.year - self.birthday.year - (self.birthday.to_time.change(:year => Time.zone.now.year) >
Time.zone.now ? 1 : 0)
  end

  def can_modify?(model)
    return false unless model.respond_to?(:user)
    self.admin? || self == model.user
  end

  def groups(options = {})
    options[:order] ||= "activity_rate desc"
    self.membership_list.groups(options)
  end

  def member_of?(group)
    if group.kind_of?(Group)
      group = group.id
    end

    self.membership_list.has_key?(group)
  end

  def role_on(group)
    config_for(group, false).role
  end

  def owner_of?(group)
    admin? || group.owner_id == self.id || role_on(group) == "owner"
  end

  def mod_of?(group)
    owner_of?(group) || role_on(group) == "moderator" || self.reputation_on(group) >= group.reputation_constrains["moderate"].to_i
  end

  def editor_of?(group)
    if c = config_for(group, false)
      c.is_editor
    else
      false
    end
  end

  def user_of?(group)
    mod_of?(group) || self.membership_list.has_key?(group.id)
  end

  def main_language
    @main_language ||= self.language.split("-").first
  end

  def has_voted?(voteable)
    !vote_on(voteable).nil?
  end

  def vote_on(voteable)
    Vote.first(:voteable_type => voteable.class.to_s,
               :voteable_id => voteable.id,
               :user_id     => self.id )
  end

  def favorite?(question)
    !favorite(question).nil?
  end

  def favorite(question)
    self.favorites.first(:question_id => question._id, :user_id => self._id )
  end

  def logged!(group = nil)
    now = Time.zone.now

    if new?
      self.last_logged_at = now
    elsif group && (member_of?(group) || !group.private)
      on_activity(:login, group)
    end
  end

  def on_activity(activity, group)
    if activity == :login
      self.last_logged_at ||= Time.now
      if !self.last_logged_at.today?
        self.set( {:last_logged_at => Time.zone.now.utc} )
      end
    else
      self.update_reputation(activity, group) if activity != :login
    end
    activity_on(group, Time.zone.now)
  end

  def activity_on(group, date)
    day = date.utc.at_beginning_of_day
    last_day = config_for(group).last_activity_at

    if last_day != day
      self.set({"membership_list.#{group.id}.last_activity_at" => day})
      if last_day
        if last_day.utc.between?(day.yesterday - 12.hours, day.tomorrow)
          self.increment({"membership_list.#{group.id}.activity_days" => 1})
        elsif !last_day.utc.today? && (last_day.utc != Time.now.utc.yesterday)
          Rails.logger.info ">> Resetting act days!! last known day: #{last_day}"
          reset_activity_days!(group)
        end
      end
    end
  end

  def reset_activity_days!(group)
    self.set({"membership_list.#{group.id}.activity_days" => 0})
  end

  def upvote!(group, v = 1.0)
    self.increment({"membership_list.#{group.id}.votes_up" => v.to_f})
  end

  def downvote!(group, v = 1.0)
    self.increment({"membership_list.#{group.id}.votes_down" => v.to_f})
  end

  def update_reputation(key, group)
    value = group.reputation_rewards[key.to_s].to_i
    value = key if key.kind_of?(Integer)
    Rails.logger.info "#{self.login} received #{value} points of karma by #{key} on #{group.name}"
    current_reputation = config_for(group).reputation

    if value
      self.increment({"membership_list.#{group.id}.reputation" => value})
    end

    stats = self.reputation_stats(group, { :select => [:_id] })
    stats.save if stats.new?

    event = ReputationEvent.new(:time => Time.now, :event => key,
                                :reputation => current_reputation,
                                :delta => value )
    ReputationStat.collection.update({:_id => stats.id}, {:$addToSet => {:events => event.attributes}})
  end

  def reputation_on(group)
    config_for(group, false).reputation.to_i
  end

  def stats(*extra_fields)
    fields = [:_id]
    UserStat.find_or_create_by_user_id(self._id, :select => fields+extra_fields)
  end

  def follow(user)
    return false if user == self
    FriendList.push_uniq(self.friend_list_id, :following_ids => user.id)
    FriendList.push_uniq(user.friend_list_id, :follower_ids => self.id)

    User.increment(self.id, :following_count => 1)
    User.increment(user.id, :followers_count => 1)

    if user.notification_opts.activities
      Notifier.delay.follow(self, user)
      Notification.create!(:user => user,
                           :event_type => "follow",
                           :origin => self)
    end

    self.remove_suggestion(user)
    true
  end

  def unfollow(user)
    return false if user == self
    FriendList.pull(self.friend_list_id, :following_ids => user.id)
    FriendList.pull(user.friend_list_id, :follower_ids => self.id)

    User.decrement(self.id, :following_count => 1)
    User.decrement(user.id, :followers_count => 1)

    self.mark_as_uninteresting(user)
    true
  end

  def followers
    self.friend_list.followers
  end

  def following
    self.friend_list.following
  end

  def following?(user)
    friend_list(:select => [:following_ids]).following_ids.include?(user.id)
  end

  def viewed_on!(group)
    self.collection.update({:_id => self._id},
                           {:$inc => {"membership_list.#{group.id}.views_count" => 1.0}},
                            :upsert => true)
  end

  def method_missing(method, *args, &block)
    if !args.empty? && method.to_s =~ /can_(\w*)\_on?/
      key = $1
      group = args.first
      if group.reputation_constrains.include?(key.to_s)
        if group.has_reputation_constrains
          return self.owner_of?(group) || self.mod_of?(group) || (self.reputation_on(group) >= group.reputation_constrains[key].to_i)
        else
          return true
        end
      end
    end
    super(method, *args, &block)
  end

  def config_for(group, init = true)
    if group.kind_of?(Group)
      group = group.id
    end

    config = self.membership_list[group]
    if config.nil?
      if init
        config = self.membership_list[group] = Membership.new(:group_id => group)
      else
        config = Membership.new(:group_id => group)
      end
    end
    config
  end

  def reputation_stats(group, options = {})
    if group.kind_of?(Group)
      group = group.id
    end
    default_options = { :user_id => self.id,
                        :group_id => group}
    stats = ReputationStat.first(default_options.merge(options)) ||
            ReputationStat.new(default_options)
  end

  def has_flagged?(flaggeable)
    flaggeable.flags.first(:user_id=>self.id)
  end

  def generate_uuid
    self.feed_token = UUIDTools::UUID.random_create.hexdigest
  end

  # Attempts to add more updates from origin to the user's feed when
  # it is too small
  def populate_news_feed!(origin)
    limit = self.news_items.count > 1000 ? 5 : 100
    total_feeded = 0
    case origin
    when User
      NewsUpdate.query(
        :author_id => origin.id,
        :order => :created_at.desc
      ).each do |update|
        return if total_feeded >= limit
        if NewsItem.query(:recipient_id => self.id,
                          :recipient_type => "User",
                          :news_update_id => update.id).count == 0
          NewsItem.notify!(update, self, origin, update.created_at)
          total_feeded += 1
        end
      end
    when Topic
      NewsItem.query(
        :recipient_id => origin.id,
        :recipient_type => "Topic",
        :order => :created_at.desc
      ).each do |item|
        return if total_feeded >= limit
        if NewsItem.query(:recipient_id => self.id,
                          :recipient_type => "User",
                          :news_update_id => item.news_update_id).count == 0
          NewsItem.notify!(item.news_update, self, origin, item.created_at)
          total_feeded += 1
        end
      end
    end
  end
  handle_asynchronously :populate_news_feed!

  # Return the user's associated Facebook account, if there is one,
  # and nil otherwise.
  def facebook_account
    self.external_accounts.first(:provider => "facebook")
  end

  # Return a Koala::Facebook::GraphAPI object to access the user's
  # Facebook account, or nil if the user doesn't have an associated
  # account.
  def facebook_connection
    if account = self.facebook_account
      return Koala::Facebook::GraphAPI.new(account.credentials["token"])
    end

    return nil
  end

  # Return the user's associated Twitter account, if there is one, and
  # nil otherwise.
  def twitter_account
    self.external_accounts.first(:provider => "twitter")
  end

  # Return a Twitter::Client object to access the user's Twitter
  # account, or nil if the user doesn't have an associated account.
  def twitter_client
    if account = self.twitter_account
      Twitter.configure do |config|
        config.consumer_key = AppConfig.twitter['key']
        config.consumer_secret = AppConfig.twitter['secret']
        config.oauth_token = account.credentials['token']
        config.oauth_token_secret = account.credentials['secret']
      end

      return Twitter::Client.new
    end

    return nil
  end

  # Return the user's associated DAC account, if there is one, and
  # nil otherwise.
  def dac_account
    self.external_accounts.first(:provider => "dac")
  end

  # Return a Student object to access the user's DAC account, or
  # nil if the user doesn't have an associated account.
  def dac_client
    if account = self.dac_account
      return Student.find_by_id(account.user_info['student'])
    end

    return nil
  end

  # Find users using self's external accounts. We simply ignore errors
  # when we stumble upon them.
  def find_external_contacts
    external_contacts = Set.new

    # Look in Facebook
    begin
      if account = self.facebook_account
        graph = Koala::Facebook::GraphAPI.new(account.credentials["token"])
        ids = graph.get_connections("me", "friends").map {|friend| friend["id"]}
        external_contacts += ExternalAccount.query(:provider => "facebook",
                                                   :uid.in => ids).map(&:user)
      end
    rescue Koala::Facebook::APIError
      # Ignore
    end

    # Look in Twitter
    begin
      if client = self.twitter_client
        ids = client.friends.users.map {|friend| friend.id.to_s}
        external_contacts += ExternalAccount.query(:provider => "twitter",
                                                   :uid.in => ids).map(&:user)
      end
    rescue Twitter::Error
      # Ignore
    end

    external_contacts.to_a
  end

  # Find interesting topics using self's external accounts.
  def find_external_topics
    topics = Set.new

    begin
      if account = self.facebook_account
        graph = Koala::Facebook::GraphAPI.new(account.credentials["token"])
        likes = graph.get_connections("me", "likes")
        likes.each do |like|
          topic = Topic.first(:title => [/^#{Regexp.escape like["name"]}/i])
          if topic
            topics << topic
          end
        end
      end
    rescue Koala::Facebook::APIError
      # Ignore
    end

    topics
  end

  def can_post_more_answers_on?(question)
    return Answer.count(:question_id => question.id, :user_id => self.id) == 0
  end

  # HACK - As we cannot provide translations for validatable
  # validations set up by devise, we translate them by hand.
  def translate_errors
    if self.errors[:email].present?
      self.errors[:email].map! do |error|
        case error
        when "can't be empty"
          I18n.t("users.validation.errors.empty_email")
        when "has already been taken"
          I18n.t("users.validation.errors.dup_email")
        when "is invalid"
          I18n.t("users.validation.errors.invalid_email")
        else
          error
        end
      end
    end

    if self.errors[:password].present?
      self.errors[:password].map! do |error|
        case error
        when "doesn't match confirmation"
          I18n.t("users.validation.errors.password_match")
        when "is invalid"
          I18n.t("users.validation.errors.invalid_password")
        when "can't be empty"
          I18n.t("users.validation.errors.empty_password")
        else
          error
        end
      end
    end
  end

  def search_entry
    {
      :id => self.id,
      :title => self.name,
      :photo_url => Helper.instance.avatar_for(self, :size => 20),
      :entry_type => "User"
    }
  end

  # Updates caused by changes in external accounts are handled by the
  # external accounts class.
  def needs_to_update_search_index?
    self.name_changed?
  end

  # Return all unread notifications
  def unread_notifications
    if date = self.last_read_notifications_at
      self.notifications.query(:created_at.gt => date)
    else
      self.notifications
    end
  end

  protected
  def password_required?
    (encrypted_password.blank? || !password.blank?)
  end

  def create_friend_list
    if !self.friend_list.present?
      self.friend_list = FriendList.new
    end
  end

  def create_notification_opts
    if !self.notification_opts
      self.notification_opts = NotificationConfig.new
    end
  end

  def strip_email
    self.email = self.email.strip
  end

  # Create a suggestion list for the user. Used with an after_create.
  def create_suggestion_list
    self.suggestion_list = SuggestionList.new(:user => self)
    self.save :validate => false
  end
end
