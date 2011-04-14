# -*- coding: utf-8 -*-
class AnswerRequestsController < ApplicationController
  def new
    @answer_request = AnswerRequest.new(:question_id => params[:question_id])

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :html => render_to_string(:layout => false)}
      end
    end

  end

  def create
    @answer_request = AnswerRequest.new
    @answer_request.sender_ids << current_user.id
    @answer_request.safe_update(["question_id", "invited_id", "message"],
                                params[:answer_request])
    @answer_request.save
    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :message => "Usuário convidado"
        }
      end
    end
  end
end
