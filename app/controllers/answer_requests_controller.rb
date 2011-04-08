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
    end

    @answer_request = AnswerRequest.new(:invited_id => params[:user_id])

    respond_to do |format|
      format.js do
        render :json => {
          :success => true,
          :html => render_to_string(:layout => false)}
      end
    end

  end

  def invitation
    @answer_request = AnswerRequest.new
    respond_to do |format|
      format.html
      format.json do
        render :json => {
          :html => render_to_string(:layout => false)
        }
      end
    end
  end

  def create
  end
end
