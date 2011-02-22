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

  def add_dac_student
    fake_student = Student.new
    fake_student.safe_update("code", params[:student])
    unicamp = University.find_by_short_name("Unicamp")

    if !(fake_student.code =~ /(\d){6,6}/)
      respond_to do |format|
        flash[:error] = I18n.t("external_accounts.dac.invalid_code")
        format.html { redirect_to session["omniauth_return_url"] }
      end
      return
    end

    unless (student = Student.first(:code => fake_student.code, :university_id => unicamp.id))
      fake_student.name = current_user.name
      fake_student.university = unicamp
      fake_student.save
      student = fake_student
    end

    unless affiliation = Affiliation.first(:user_id => current_user.id.to_s, :university_id => unicamp.id)
       affiliation = Affiliation.new(:university_id => unicamp.id, :user_id => current_user.id.to_s)
    end
    email = "#{current_user.name[0,1].downcase}#{student.code}@dac.unicamp.br"
    affiliation.email = email
    affiliation.student_id = student.id

    unless affiliation.save
      respond_to do |format|
        flash[:error] = I18n.t("external_accounts.dac.invalid_code")
        format.html { redirect_to session["omniauth_return_url"] }
      end
      return
    end

    current_user.affiliations << affiliation
    current_user.save
    respond_to do |format|
      format.html { redirect_to session["omniauth_return_url"] }
    end
  end
end
