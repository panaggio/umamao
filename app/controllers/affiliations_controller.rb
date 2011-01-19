class AffiliationsController < ApplicationController
  def create
    email = params[:affiliation][:email]
    uni_id = University.find_id_by_email_domain(email)
    status = :success

    # If we don't recognize the email as being from any university,
    # add it to waiting list
    if uni_id.blank?
      @waiting_user = WaitingUser.new
      @waiting_user.email = email

      if @waiting_user.save
        track_event(:new_waiting_user)
        notice = t("affiliations.create.email_sent")

      elsif @waiting_user.errors[:email].present?
        status, error_message =
          process_email_errors(@waiting_user.errors[:email]){
          WaitingUser.resend_wait_note(email)
        }
      else
        status = :error
        error_message = @waiting_user.errors.full_messages.join("**")
      end
    else
      @affiliation = Affiliation.new
      @affiliation.university_id = uni_id
      @affiliation.email = email

      if @affiliation.save
        track_event(:new_affiliation)
        notice = t("affiliations.create.email_sent")
      elsif @affiliation.errors[:email].present?
        status, error_message =
          process_email_errors(@affiliation.errors[:email]){
          Affiliation.resend_confirmation(email)
        }
      else
        error_message = @affiliation.errors.full_messages.join("**")
      end
    end

    # Responding
    respond_to do |format|
      format.js do
        case status
        when :success
          success = true
          message = notice
        when :duplicate
          # Normally, this would be an error, but we don't want to
          # scare users.
          success = true
          message = error_message
        when :error
          success = false
          message = notice
        end

        render :json => {
          :success => success,
          :message => message
        }.to_json
      end
    end
  end

  protected
  def process_email_errors(errors)
    # TODO: Put this somewhere else (errors module?) Part II
    status = :duplicate
    error_message = errors.map {|e|
      case e
      when "has already been taken"
        yield # resends confirmation
        t("affiliations.messages.errors.email_in_use")
      else
        status = :error
        e
      end
    }.join(" ")
    return [status, error_message]
  end

end
