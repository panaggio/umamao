module NotificationsHelper

  def notification_message(notification)
    user = notification.info[:user]
    case notification.event_type
    when "new_answer", "new_comment"
      question = notification.info[:question]
      I18n.t("notifications.#{notification.event_type}",
             :user => link_to(h(short_name(user)), user_path(user)),
             :question => link_to(h(question.title),
                                  question_path(question)))
    when "follow"
      I18n.t("notifications.follow", :user => link_to(h(short_name(user)),
                                                      user_path(user)))
    end
  end
end

