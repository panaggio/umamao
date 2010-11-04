class SearchesController < ApplicationController
  include GravatarHelper::PublicMethods

  def index
    options = {:per_page => 25, :page => params[:page] || 1}
    unless params[:q].blank?
      pharse = params[:q].downcase
      @search_tags = pharse.scan(/\[(.*?)\]/).flatten
      @search_text = pharse.gsub(/\[.*?\]/, "")
      options[:tags] = {:$all => @search_tags} unless @search_tags.empty?
      options[:group_id] = current_group.id
      options[:order] = params[:sort_by] if params[:sort_by]
      options[:banned] = false

      if !@search_text.blank?
        q = @search_text.split.map do |k|
          Regexp.escape(k)
        end.join("|")
        @query_regexp = /(#{q})/i
        @questions = Question.filter(@search_text, options)
      else
        @questions = Question.paginate(options)
      end
    else
      @questions = []
    end

    respond_to do |format|
      format.html
      format.js do
        render :json => {:html => render_to_string(:partial => "questions/question",
                                                   :collection  => @questions)}.to_json
      end
    end
  end

  def json
    # Searches for entries containing keywords in the search box and
    # returns them in JSON form

    phrase = params[:q]

    questions = Question.filter(phrase, :per_page => 10,
                                :select => [:title, :slug]).map do |q|
      {
        :title => q.title,
        :url => question_url(q),
        :type => "Question",
        :topics => []
      }
    end
    topics = Topic.filter(phrase, :per_page => 10,
                          :select => [:title, :slug]).map do |t|
      {
        :title => t.title,
        :url => topic_url(t),
        :type => "Topic"
      }
    end
    users = User.filter(phrase, :per_page => 10,
                        :select => [:name, :slug, :email]).map do |u|
      {
        :title => u.name,
        :url => user_url(u),
        :type => "User",
        :pic => gravatar(u.email.to_s, :size => 20)
      }
    end

    render :json => (questions[0 .. 3] + topics[0 .. 2] + users[0 .. 2]).to_json
  end
end
