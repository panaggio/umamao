class WelcomeController < ApplicationController
  helper :questions
  tabs :default => :welcome
  layout 'application'

  def index
    logged_in? ? home : landing
  end

  def landing
    @affiliation = Affiliation.new
    @waiting_user = WaitingUser.new
    render 'landing', :layout => 'welcome'
  end

  def home
    @active_subtab = params.fetch(:tab, "activity")

    @news_items = NewsItem.paginate({:recipient_id => current_user.id,
                                      :recipient_type => "User",
                                      :per_page => 30,
                                      :page => params[:page] || 1,
                                      :order => :created_at.desc})
    @questions = Question.latest.limit(10) || [] if @news_items.empty?
    render 'home'
  end

  def about
    set_page_title(t('.welcome.about.title'))
    @users = AppConfig.about['users']
    render 'about', :layout => 'welcome'
  end

  def feedback
    render 'feedback', :layout => 'welcome'
  end

  def send_feedback
    ok = !params[:result].blank? &&
         (params[:result].to_i == (params[:n1].to_i * params[:n2].to_i))

    if !ok
      flash[:error] = I18n.t("welcome.feedback.captcha_error")
      redirect_to feedback_path(:feedback => params[:feedback])
    else
      Notifier.new_feedback(current_user, params[:feedback][:title],
                                                  params[:feedback][:description],
                                                  params[:feedback][:email],
                                                  request.remote_ip).deliver
      redirect_to root_path
    end
  end

  def change_language_filter
    if logged_in? && params[:language][:filter]
      current_user.update_language_filter(params[:language][:filter])
    elsif params[:language][:filter]
      session["user.language_filter"] =  params[:language][:filter]
    end
    respond_to do |format|
      format.html {redirect_to(params[:source] || questions_path)}
    end
  end

  def confirm_age
    if request.post?
      session[:age_confirmed] = true
    end

    redirect_to params[:source].to_s[0,1]=="/" ? params[:source] : root_path
  end
end

