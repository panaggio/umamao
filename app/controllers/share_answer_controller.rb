# This controller is used to share questions on other websites

class ShareAnswerController < ShareContentController
  CONTENT_CLASS = Answer

  protected
  def content_url(answer, options={})
    question_answer_url(answer.question,answer, options)
  end

  def content_path(answer)
    question_answer_path(answer.question, answer)
  end

  # Facebook: "Answer (by John Doe): Is this a good question?"
  # Twitter:  "Answer (by @johndoe) on Umamão: Is this a good question? http://bit.ly/umamao"
  def default_body
    twitter, facebook = {:site => AppConfig.application_name}, {:site => AppConfig.application_name}

    if current_user == @content.user
      {
        'facebook' => "#{t("answers.share_body.facebook_self", facebook)}: #{@content.title}",
        'twitter' => "#{t("answers.share_body.twitter_self", twitter)}: #{@content.title}"
      }
    else
      @content.user.external_accounts.each do |ea|
        case ea.provider
        when 'facebook'
          facebook[:name] = ea.user_info['name']
        when 'twitter'
          twitter[:name] = "@#{ea.user_info['nickname']}"
        end
      end

      {
        'facebook' => "#{ t("answers.share_body.facebook#{"_named" if facebook[:name].present?}", facebook)}: #{@content.title}",
        'twitter' => "#{t("answers.share_body.twitter#{"_named" if twitter[:name].present?}", twitter)}: #{@content.title}"
      }
    end
  end
end
