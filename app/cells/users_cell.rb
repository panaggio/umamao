class UsersCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper
  helper UsersHelper

  # List of users with small avatars.
  def list
    @users = @opts[:users]
    @title = @opts[:title]
    render
  end

  def small_picture
    @user = options[:user]
    render
  end

end
