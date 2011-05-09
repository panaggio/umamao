# -*- coding: utf-8 -*-
class QuestionListsController < TopicsController
  before_filter :login_required, :except => [:show, :print, :questions_print]
  before_filter :main_topic_allow_question_lists, :only => [:new, :create]
  before_filter :check_permissions, :only => [:destroy]

  # GET /question_lists/new
  def new
    @question_list = QuestionList.new :main_topic => @main_topic

    now = Time.now
    @sample_title = t("question_lists.new.sample_title",
                      :title => @question_list.main_topic.title,
                      :semester => now.month < 7 ? 1 : 2,
                      :year => now.year)
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
      flash[:notice] = t("question_lists.create.success")
      redirect_to question_list_path(@question_list)
    else
      if QuestionList.find_by_title(params[:question_list][:title])
        flash[:error] = t('question_lists.create.error.existing_list')
      else
        flash[:error] = t('question_lists.create.error.default')
      end
      render :action => "new"
    end
  end

  def destroy
    topic = @question_list.main_topic
    @question_list.destroy
    redirect_to topic_path(topic)
  end

  # GET /question_lists/1
  def show
    show_init
    set_tab :all, :question_list_show

    @open_sharing_widget = flash[:connected_to]

    @new_question = Question.new
  end

  def questions_print
    print_init
    track_event(:print_questions)
  end

  def print
    print_init
    track_event(:print_full_list)
  end

  # GET /question_lists/1/unanswered
  def unanswered
    show_init('is_open' => true)
    set_tab :unanswered, :question_list_show

    respond_to do |format|
      format.html { render 'show' }
    end
  end

  # FIXME: Merge with QuestionsController#classify via a common module
  # Classifies the question_list under a certain topic.
  def classify
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

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
          :partial => 'topics/topic_box',
          :locals => {
            :topic => @topic,
            :options => {
              :ajax_add => true,
              :logged_in => true,
              :classifiable => @question_list
            }
          }
        ) if status
        render :json => res.to_json
      end
    end
  end

  # FIXME: Merge with QuestionsController#unclassify via a common module
  # Removes a question_list from a certain topic.
  def unclassify
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

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

  def create_file
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

    @file = QuestionListFile.new(:file => params[:file],
                                 :user => current_user,
                                 :group => current_group,
                                 :question_list => @question_list)

    if !@file.save
      flash[:error] = "#{t("question_lists.create_file.error")}: "
      flash[:error] += @file.errors[:file].join ' '
    end

    redirect_to question_list_path(@question_list)
  end

  def destroy_file
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

    @file = @question_list.question_list_files.find(params[:file])

    if @file.present? && @file.can_be_destroyed_by?(current_user)
      @file.destroy
    else
      flash[:error] = t("question_lists.destroy_file.error")
    end

    redirect_to question_list_path(@question_list)
  end

  protected
  def calculate_unanswered_count
    @question_list.questions.count(:is_open => true)
  end

  def show_init(query = {})
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

    @unanswered_questions_count = calculate_unanswered_count

    set_page_title(@question_list.title)

    @page = params[:page] || 1

    options = {
      :per_page => 20, :page => @page,
      :order => [:votes, "created_at asc"], :banned => false
    }

    @questions = @question_list.questions.query(query).paginate(options)
  end

  def print_init
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

    set_page_title(@question_list.title)

    @questions = @question_list.questions
  end

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

  def check_permissions
    @question_list = QuestionList.find_by_slug_or_id(params[:id])

    raise Goalie::NotFound unless @question_list

    if @question_list.user != current_user && !current_user.admin?
      flash[:error] = t("global.permission_denied")
      redirect_to question_list_path(@question_list)
    end
  end
end
