# Bulk-following of topics in user settings.

class Settings::FollowTopicsController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :follow_topics, :settings

  def edit
    @active = 'follow'
    @user_topics = UserTopicInfo.query(:user_id => current_user.id,
                                  :following => true).
      paginate(:per_page => 100, :page => params[:page] || 1)
  end

end
