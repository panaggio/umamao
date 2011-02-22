class UsersCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper
  helper UsersHelper

  cache :followers do |cell, options|
    user = cell.options[:user]
    "#{user.id}/#{user.followers.count}"
  end

  cache :following do |cell, options|
    user = cell.options[:user]
    "#{user.id}/#{user.following.count}"
  end

  def followers
    @user = options[:user]
    @users = @user.followers
    render
  end

  def following
    @user = options[:user]
    @users = @user.following
    render
  end

  # List of users with small avatars.
  def list
    @users ||= options[:users]
    @title ||= options[:title]
    render
  end

  def small_picture
    @user = options[:user]
    render
  end

end
