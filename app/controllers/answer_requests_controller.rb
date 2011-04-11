# -*- coding: utf-8 -*-
class AnswerRequestsController < ApplicationController
  def new
    invited = User.find_by_id(params[:user_id])

    unless invited
      respond_to do |format|
        format.json do
          render :json => {
            :success => false,
            :message => "Usuário não existe"
          }
        end
      end
      return
    end

    @answer_request = AnswerRequest.new(:invited_id => params[:user_id], :question_id => params[:question_id])

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :html => render_to_string(:layout => false)}
      end
    end

  end

  def invitation
    @question_id = params[:question_id]

    respond_to do |format|
      format.html
      format.js do
        render :json => {
          :success => true,
          :html => render_to_string(:layout => false)
        }
      end
    end
  end

  def create
    @answer_request = AnswerRequest.new
    @answer_request.update_attributes(params[:answer_request])
    @answer_request.senders << current_user
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
