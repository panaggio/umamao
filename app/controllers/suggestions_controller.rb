class SuggestionsController < ApplicationController
  before_filter :login_required

  def follow_user
    @followed_user = User.find_by_id(params[:user])
    if @followed_user
      success = current_user.follow(@followed_user)
    end
    respond_to do |format|
      format.js do
        render :json => {
          :success => !!success,
          :div_id => "follow#{@followed_user.id}",
          :new_link => render_to_string(:partial => "followed",
                                        :layout => false)}
      end
    end
  end

  def unfollow_user
    @unfollowed_user = User.find_by_id(params[:user])
    if @unfollowed_user
      success = current_user.unfollow(@unfollowed_user)
    end
    respond_to do |format|
      format.js do
        render :json => {
          :success => !!success,
          :div_id => "follow#{@unfollowed_user.id}",
          :new_link => render_to_string(:partial => "unfollowed",
                                        :layout => false)}
      end
    end
  end

  # Refuse suggestions.
  def refuse
    type = nil
    if params[:suggestion].present?
      @suggestion = Suggestion.find_by_id(params[:suggestion])
    elsif params[:topic].present?
      @suggestion = Suggestion.first(
        :entry_id => BSON::ObjectId(params[:topic]), :entry_type => "Topic",
        :origin => nil, :user_id => current_user.id)

      @user_suggestions = UserSuggestion.all(
        :entry_id => BSON::ObjectId(params[:topic]), :entry_type => 'Topic',
        :user_id => current_user.id)
    elsif params[:user].present?
      @suggestion = Suggestion.first(
        :entry_id => params[:user], :entry_type => "User",
        :origin => nil, :user_id => current_user.id)

      @user_suggestions = UserSuggestion.all(
        :entry_id => BSON::ObjectId(params[:user]), :entry_type => 'User',
        :user_id => current_user.id)
    end

    if @suggestion
      type = @suggestion.entry_type.underscore.pluralize.to_sym
      current_user.refuse_suggestion(@suggestion)
      current_user.save!
      track_event(:refused_suggestion)
    end

    unless @user_suggestions.empty?
      @user_suggestions.map!(&:reject!)
      track_event(:refused_user_suggestion)
    end
    @user_suggestion_went_well =
      @user_suggestions.empty? || @user_suggestions.uniq == [true]

    respond_to do |format|
      format.js do
        request_answer = {
          :success => !!@suggestion && @user_suggestion_went_well}
        if type
          request_answer[:suggestions] = render_cell :suggestions, type, :single_column => params[:single_column]
        end
        render :json => request_answer.to_json
      end
    end
  end

  # Delete suggestions
  def delete
    @user_suggestion = UserSuggestion.first(
      :entry_id => BSON::ObjectId(params[:topic]), :entry_type => 'Topic',
      :origin_id => BSON::ObjectId(params[:origin]), :user_id => current_user.id)

    track_event(:deleted_user_suggestion)

    @user_suggestion.delete!
  end
end
