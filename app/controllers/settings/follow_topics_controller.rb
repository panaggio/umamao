# Bulk-following of topics in user settings.

class Settings::FollowTopicsController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :follow_topics, :settings

  def edit
    @topics = Topic.query(:follower_ids => current_user.id).
      paginate(:per_page => 100, :page => params[:page] || 1)
  end

end
