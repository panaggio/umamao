class UsersCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper
  helper UsersHelper

  cache :followers do |cell, options|
    followed = cell.options[:followed]
    "#{followed.class.to_s.downcase}/#{followed.id}" +
      "/#{followed.followers.count}"
  end

  cache :following do |cell, options|
    follower = cell.options[:follower]
    "#{follower.id}/#{follower.following.count}"
  end

  def followers
    @followed = options[:followed]
    @users = @followed.followers
    if @followed.is_a?(Question)
      author = @followed.user
      @users = @users.to_a
      @users.delete(author)
      @users.unshift(author)
    end
    @total_followers = @followed.followers.count
    @type = @followed.collection.name.singularize
    @path =
      case @followed
      when User
        followers_user_path @followed
      when Question
        followers_question_path @followed.id
      when Topic
        followers_topic_path @followed.id
      end
    @i18n_class =
      if @followed.is_a?(Question)
        "followable.followers.question"
      else
        "followable.followers"
      end
    render
  end

  def following
    @follower = options[:follower]
    @users = @follower.following
    @total_followed = @follower.following.count
    @path = following_user_path @follower
    render
  end

  # List of users with small avatars.
  def list
    @users = (@users || options[:users]).paginate :per_page => 14
    render
  end

  def small_picture
    @user = options[:user]
    render
  end

end
