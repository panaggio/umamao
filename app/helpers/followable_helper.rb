module FollowableHelper

  # When clicked, this button toggles the follow relation between the
  # current user and the followable entity.
  #
  # TODO:
  #   - convert every follow button on the site to use this call.
  #   - make this work for other followable entities.
  def follow_button(followable, options = {})
    options = {:force => false}.merge(options)

    if !logged_in? || current_user == followable ||
        !options[:force] && (following = current_user.following?(followable))
      return ""
    end

    attributes = {
      :follow => {
        :title => t("followable.follow"),
        :path => follow_user_path(followable),
        :class => "follow_link"
      },
      :unfollow => {
        :title => t("followable.unfollow"),
        :path => unfollow_user_path(followable),
        :class => "unfollow_link"
      }
    }

    act, undo = following ? [:unfollow, :follow] : [:follow, :unfollow]

    button = '<div class="follow-info">'
    button << link_to(attributes[act][:title],
                      attributes[act][:path],
                      :class => attributes[act][:class],
                      "data-title" => attributes[undo][:title],
                      "data-undo" => attributes[undo][:path],
                      "data-class" => attributes[undo][:class])
    button << '</div>'

  end
end
