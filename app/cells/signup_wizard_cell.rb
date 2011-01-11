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
    render
  end

  def follow
    @current_user = current_user
    # We begin by populating the suggestions list.
    if @current_user.suggested_user_ids.blank?
      @current_user.find_external_contacts.each do |user|
        unless @current_user.following?(user) ||
            @current_user.uninteresting_user_ids.include?(user.id)
          @current_user.suggested_users << user
        end
      end
    end

    if @current_user.suggested_topic_ids.blank?
      @current_user.find_topics.each do |topic|
        unless topic.follower_ids.include?(@current_user.id)
          @current_user.suggested_topic_ids << topic.id
        end
      end
      @current_user.randomize_topic_suggestions
      @current_user.suggested_topics_fresh = true
    end

    @current_user.save
    render
  end

end
