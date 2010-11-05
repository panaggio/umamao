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

    query_res = phrase.split.map {|w| Regexp.new "^#{Regexp.escape w}"}

    questions = Question.query(:autocomplete_keywords.in => query_res,
                               :select => [:title, :slug, :topic_ids]).limit(10)
    topics = Topic.filter(phrase, :per_page => 10,
                          :select => [:title, :slug])
    users = User.filter(phrase, :per_page => 10,
                        :select => [:name, :id, :email])

    # index calculation to sum 10 results and balance between classes
    total_qs = questions.count
    total_ts = topics.length
    total_us = users.length

    total_qs = [total_qs, 10 - [total_ts + total_us, 6].min].min
    total_ts = [total_ts, 10 - total_qs - [total_us, 7 - total_qs].min].min
    total_us = [total_us, 10 - total_qs - total_ts].min

    # JSON serialization
    render :json => ((questions.limit(total_qs).map do |q|
                        {
                          :title => q.title,
                          :url => url_for(q),
                          :type => "Question",
                          :topics => q.topics.map(&:title)
                        }
                      end) +
                     (topics[0...total_ts].map do |t|
                        {
                          :title => t.title,
                          :url => url_for(t),
                          :type => "Topic"
                        }
                      end) +
                     (users[0...total_us].map do |u|
                        {
                          :title => u.name,
                          :url => url_for(u),
                          :type => "User",
                          :pic => gravatar(u.email.to_s, :size => 20)
                        }
                      end)).to_json
  end
end
