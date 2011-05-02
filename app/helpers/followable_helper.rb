module FollowableHelper

  # When clicked, this button toggles the follow relation between the
  # current user and the followable entity.
  def follow_button(followable, options = {})
    options = {:only_if_unfollowed => false}.merge(options)

    return "" if !logged_in? || current_user == followable

    if followable.is_a?(User)
      follow_path = follow_user_path(followable, :format => :js)
      unfollow_path = unfollow_user_path(followable, :format => :js)
      following = current_user.following?(followable)
      entry_type = "user"
    elsif followable.is_a?(Topic)
      follow_path = follow_topic_path(followable, :format => :js)
      unfollow_path = unfollow_topic_path(followable, :format => :js)
      following = followable.follower_ids.include?(current_user.id)
      entry_type = "topic"
    elsif followable.is_a?(Question)
      follow_path = watch_question_path(followable, :format => :js)
      unfollow_path = unwatch_question_path(followable, :format => :js)
      following = followable.watch_for?(current_user)
      entry_type = "question"
    else
      follow_path = ""
      unfollow_path = ""
      following = false
      entry_type = ""
    end

    return "" if options[:only_if_unfollowed] && following

    attributes = {
      :follow => {
        :title => t("followable.follow"),
        :path => follow_path,
        :class => "follow_link"
      },
      :unfollow => {
        :title => t("followable.unfollow"),
        :path => unfollow_path,
        :class => "unfollow_link"
      }
    }

    act, undo = following ? [:unfollow, :follow] : [:follow, :unfollow]

    button = link_to(attributes[act][:title],
                     attributes[act][:path],
                     :class => attributes[act][:class],
                     :remote => true,
                     :method => :post,
                     "data-type" => "json",
                     "data-entry-type" => entry_type,
                     "data-title" => attributes[undo][:title],
                     "data-undo" => attributes[undo][:path],
                     "data-class" => attributes[undo][:class])
  end
end
