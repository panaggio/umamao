# Wizard that is displayed after a user signs up. Steps through
# external accounts integration, topics and users suggestions.

class SignupWizardCell < Cell::Rails
  include Devise::Controllers::Helpers
  helper ApplicationHelper

  def wizard
    @steps = ["connect", "follow"]
    @current_step = params[:current_step]
    current_step_idx = @steps.index(@current_step)
    @previous_step = current_step_idx == 0 ? nil : @steps[current_step_idx - 1]
    @next_step = @steps[current_step_idx + 1]
    @user = @opts[:user]
    render
  end

  def follow
    # We begin by populating the suggestions list.
    if @user.suggested_user_ids.blank?
      @user.find_users.each do |user|
        unless @user.following?(user)
          @user.suggested_users << user
        end
      end
    end
    if @user.suggested_topic_ids.blank?
      @user.find_topics.each do |topic|
        unless topic.follower_ids.include?(@user.id)
          @user.suggested_topic_ids << topic.id
        end
      end
      @user.suggested_topics_fresh = true
    end
    @user.save
    render
  end

end
