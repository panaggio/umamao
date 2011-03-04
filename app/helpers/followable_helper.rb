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
        !options[:force] && (f = current_user.following?(followable))
      return ""
    end

    attributes = {
      false => {
        :title => t("followable.follow"),
        :path => follow_user_path(followable),
        :class => "follow_link"
      },
      true => {
        :title => t("followable.unfollow"),
        :path => unfollow_user_path(followable),
        :class => "unfollow_link"
      }
    }

    button = '<div class="follow-info">'
    button << link_to(attributes[f][:title], attributes[f][:path],
                      :class => attributes[f][:class],
                      "data-title" => attributes[!f][:title],
                      "data-undo" => attributes[!f][:path],
                      "data-class" => attributes[!f][:class])
    button << '</div>'

  end
end
