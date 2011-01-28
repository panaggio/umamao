class UsersCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper
  helper UsersHelper

  def list
    @users = @opts[:users]
    @title = @opts[:title]
    render
  end

end
