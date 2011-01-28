# -*- coding: utf-8 -*-
class AffiliationsController < ApplicationController
  def create
    email = params[:affiliation][:email].try(:strip)
    status = nil

    if @affiliation = Affiliation.find_by_email(email)
      # Try to see whether we have already gotten this address.
      if @affiliation.user.present?
        status = :error
        message = t("affiliations.errors.duplicate_email")
      elsif @affiliation.confirmed_at.present?
        status = :confirmed
        url = new_user_url(:affiliation_token => @affiliation.affiliation_token)
      else
        status = :success
        message = t("affiliations.create.email_sent")
        Affiliation.resend_confirmation(email)
      end

    elsif university_id = University.find_id_by_email_domain(email)
      # Check if this is a valid academic email
      @affiliation = Affiliation.new(:university_id => university_id,
                                     :email => email)

      if @affiliation.save
        status = :success
        message = t("affiliations.create.email_sent")
        track_event(:new_affiliation)

        if email =~ /^\w[0-9]{6}@dac.unicamp.br$/
          # User doesn't have to confirm
          status = :confirmed
          url = new_user_url(:affiliation_token =>
                             @affiliation.affiliation_token)
          @affiliation.confirmed_at = Time.now
          @affiliation.save
        end
      else
        status = :error
        if @affiliations.errors[:email].present?
          message = t("affiliations.errors.invalid_email")
        else
          message = t("affiliations.errors.unknown")
        end
      end

    elsif @user = User.find_by_email(email)
      status = :error
      message = t("affiliations.errors.duplicate_email")

    elsif @waiting_user = WaitingUser.find_by_email(email)
      # Check for existing waiting user.
      status = :success
      message = t("affiliations.create.email_sent")
      WaitingUser.resend_wait_note(email)

    else
      # Non-academic user. Add to waiting list.
      @waiting_user = WaitingUser.new(:email => email)

      if @waiting_user.save
        status = :success
        message = t("affiliations.create.email_sent")
        track_event(:new_waiting_user)
      else
        status = :error
        if @waiting_user.errors[:email].present?
          message = t("affiliations.errors.invalid_email")
        else
          message = t("affiliations.errors.unknown")
        end
      end

    end

    respond_to do |format|
      format.js do
        response =
          case status
          when :success
            {:success => true, :message => message}
          when :confirmed
            {:success => true, :url => url}
          when :error
            {:success => false, :message => message}
          end
        render :json => response.to_json
      end
    end
  end

end
