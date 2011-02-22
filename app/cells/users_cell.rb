class UsersCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper
  helper UsersHelper

  cache :list do |cell, options|
    cell.options[:cache_key]
  end

  # List of users with small avatars.
  def list
    @users = options[:users]
    @title = options[:title]
    @cache_key = options[:cache_key]
    render
  end

  def small_picture
    @user = options[:user]
    render
  end

end
