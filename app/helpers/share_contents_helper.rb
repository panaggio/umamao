module ShareContentsHelper
  def default_message_group_invitation(content)
    if content.kind_of? Topic
      t("topics.group_invitation.message", 
                  {:topic => content.title, 
                    :link_topic => topics_path(content)})
    else
      t("share_content.group_invitation.message")
    end

  end
end
