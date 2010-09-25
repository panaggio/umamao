class InvitationsController < ApplicationController
  before_filter :fetch_invitations

  def index
    @invitation = Invitation.new
  end

  def create
    @invitation = Invitation.new(params[:invitation])
    @invitation.sender_id = current_user.id
    @invitation.group_id = current_group.id

    if @invitation.save
      redirect_to invitations_path
    else
      render 'index'
    end
  end

  private
  def fetch_invitations
    @pending_invitations = Invitation.where(:sender_id => current_user.id,
                                             :accepted_at => nil)
    @accepted_invitations = Invitation.where(:sender_id => current_user.id,
                                             :accepted_at.ne => nil)
  end

end
