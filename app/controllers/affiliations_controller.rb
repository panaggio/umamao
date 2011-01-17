class AffiliationsController < ApplicationController
  def create
    email = params[:affiliation][:email]
    uni_id = University.find_id_by_email_domain(email)

    # If we don't recognize the email as being from any university,
    # add it to waiting list
    if uni_id.blank?
      @waiting_user = WaitingUser.new
      @waiting_user.email = email

      if @waiting_user.save
        track_event(:new_waiting_user)
        flash[:notice] = t("affiliations.create.email_sent")

      else if @waiting_user.errors[:email].present?
          # TODO: Put this somewhere else (errors module?) Part II
          flash[:error] = ""
          @waiting_user.errors[:email].each do |e|
            case e
              when "has already been taken"
                flash[:error] << " " << t("affiliations.messages.errors.email_in_use")
                WaitingUser.resend_wait_note(email) # resends confirmation
              else
                flash[:error] << " " << e
              end
          end

        else
          flash[:error] = @waiting_user.errors.full_messages.join("**")
        end
      end
    else
      @affiliation = Affiliation.new
      @affiliation.university_id = uni_id
      @affiliation.email = email

      if @affiliation.save
        track_event(:new_affiliation)
        flash[:notice] = t("affiliations.create.email_sent")

      else
        # TODO: Put this somewhere else (errors module?) Part II
        if @affiliation.errors[:email].present?
          flash[:error] = ""
          @affiliation.errors[:email].each do |e|

            case e
              when "has already been taken"
                flash[:error] << " " << t("affiliations.messages.errors.email_in_use")
                Affiliation.resend_confirmation(email) #resends confirmation
              else
                  flash[:error] << " " << e
              end
          end

        else
          flash[:error] = @affiliation.errors.full_messages.join("**")
        end
      end
    end

    # Responding
    if flash[:error].present?
        respond_to do |format|
          format.js {
            render(:json => {:success => false,
                             :message => flash[:error] }.to_json)
          }
        end

    elsif flash[:notice].present?
        respond_to do |format|
          format.js {
            render(:json => {:success => true,
                             :message => flash[:notice] }.to_json)
          }
        end
    end
  end
end


