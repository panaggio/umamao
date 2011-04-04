# -*- coding: utf-8 -*-
class QuestionListsController < ApplicationController
  before_filter :login_required, :except => [:show]
  before_filter :main_topic_allow_question_lists, :only => [:new, :create]

  # GET /question_lists/new
  def new
    @question_list = QuestionList.new
    @question_list.main_topic = @main_topic
  end

  # POST /question_lists
  def create
    @question_list = QuestionList.new
    @question_list.title = params[:question_list][:title]
    @question_list.description = params[:question_list][:description]
    @question_list.main_topic = @main_topic
    @question_list.user = current_user
    @question_list.topics = Topic.from_titles!(params[:question_list][:topics])
    @question_list.topics << @question_list.main_topic

    if @question_list.save
      flash[:notice] = t(:flash_notice, :scope => "question_lists.create")
    end
    redirect_to(topic_path(@question_list.main_topic))
  end

  def show
    @question_list = QuestionList.find_by_slug_or_id(params[:id])
    options = {
      :per_page => 10, :page => params[:page] || 1,
      :order => [:votes, "created_at desc"], :banned => false
    }
    @questions = @question_list.questions.paginate(options)
  end

  def edit
    @question_list = QuestionList.find_by_slug_or_id(params[:id])
    options = {
      :per_page => 10, :page => params[:page] || 1,
      :order => [:votes, "created_at desc"], :banned => false
    }
    @questions = @question_list.questions.paginate(options)
  end

  protected
  def main_topic_allow_question_lists
    @main_topic = Topic.find_by_slug_or_id(params[:main_topic] ||
                                           params[:question_list][:main_topic])
    unless @main_topic.allow_question_lists
      flash[:error] = t(:topic_does_not_allow,
                        :scope => "question_lists.create",
                        :title => @main_topic.title)
      redirect_to(topic_path(@main_topic))
    end
  end
end
