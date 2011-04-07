# Bulk-following of topics in user settings.

class Settings::IgnoreTopicsController < ApplicationController
  before_filter :login_required
  layout 'settings'
  set_tab :follow_topics, :settings

  def edit
    @active = 'ignore'
    @topics = current_user.ignored_topics.
      paginate(:per_page => 100, :page => params[:page] || 1)

    render 'settings/follow_topics/edit'
  end

end
