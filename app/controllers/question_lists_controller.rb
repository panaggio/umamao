# -*- coding: utf-8 -*-
class QuestionListsController < TopicsController
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

    # The "#form" suffix below is used to open the "new question
    # form", which is supposed to be the main use case right after you
    # create a new question list.
    redirect_to("#{question_list_path(@question_list)}#form")
  end

  # GET /question_lists/1
  def show
    @question_list = QuestionList.find_by_slug_or_id(params[:id])
    @page = params[:page] || 1
    options = {
      :per_page => 20, :page => @page,
      :order => [:votes, "created_at asc"], :banned => false
    }
    @questions = @question_list.questions.paginate(options)
    @new_question = Question.new
  end

  # FIXME: Merge with QuestionsController#classify via a common module
  # Classifies the question_list under a certain topic.
  def classify
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    @topic = Topic.find_by_title(params[:topic])

    # Create new topic when it doesn't exist yet.
    if @topic.nil?
      @topic = Topic.create(:title => params[:topic])
      @topic.save
    end

    @question_list.updated_by = current_user
    status = @question_list.classify! @topic

    respond_to do |format|
      format.html do
        redirect_to question_list_path(@question_list)
      end

      format.js do
        res = { :success => status }
        res[:box] = render_to_string(
          :partial => 'topics/topic_box', :locals => {
            :topic => @topic, :classifiable => @question_list,
            :options => { :ajax_add => true, :logged_in => true }
        }) if status
        render :json => res.to_json
      end
    end
  end

  # FIXME: Merge with QuestionsController#unclassify via a common module
  # Removes a question_list from a certain topic.
  def unclassify
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    @topic = Topic.find_by_title(params[:topic])
    @question_list.updated_by = current_user
    status = @question_list.unclassify! @topic

    respond_to do |format|
      format.html do
        redirect_to question_list_path(@question_list)
      end

      format.js do
        render :json => { :success => status }.to_json
      end
    end
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
