class TopicsController < ApplicationController
  before_filter :login_required, :only => [:create, :update, :destroy]
  before_filter :admin_required, :only => :destroy
  respond_to :html

  tabs :default => :topics

  def index
    set_page_title(t("layouts.application.tags"))

    order = params[:sort].try(:to_sym) || :questions_count
    set_tab order, :topics
    order = order.desc if [:questions_count, :created_at].include? order

    @topics = Topic.sort(order).paginate(:per_page => 100,
                                         :page => params[:page] || 1)

    respond_with @topics
  end

  def show
    @topic = Topic.find_by_slug_or_id(params[:id])
    @questions = Question.paginate(:topic_ids => @topic.id, :banned => false,
                                   :order => :activity_at.desc, :per_page => 25,
                                   :page => params[:page] || 1)

    respond_with @topics
  end

  def edit
    @topic = Topic.find_by_slug_or_id(params[:id])
    respond_with @topic
  end

  def create
    @topic = Topic.new(params[:topic])
    @topic.save
    respond_with @topic
  end

  def update
    @topic = Topic.find_by_slug_or_id(params[:id])
    @topic.safe_update(%w[title description], params[:topic])
    @topic.save
    respond_with @topic
  end

  def destroy
    @topic = Topic.find_by_slug_or_id(params[:id])
    @topic.destroy
    respond_with @topic
  end

end