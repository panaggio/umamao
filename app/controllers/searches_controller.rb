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

    options = {:per_page => 10}
    phrase = params[:q].downcase
    results = AutocompleteItem.filter(phrase, options).group_by do |i|
      i.entry_type
    end
    fetched = []
    results.each do |type, entries|
      if type == "Question"
        Question.all(:id.in => entries.map {|e| e[:entry_id]},
                     :select => [:title, :slug]).each do |q|
          fetched << {
            :title => q.title,
            :url => url_for(q),
            :type => "Question",
            :topics => []
          }
        end
      elsif type == "User"
        User.all(:id.in => entries.map {|e| e[:entry_id]},
                 :select => [:name, :slug]).each do |u|
          fetched << {
            :title => u.name,
            :url => url_for(u),
            :type => "User",
            :pic => gravatar(u.email.to_s, :size => 20)
          }
        end
      else # Topic
        Topic.all(:id.in => entries.map {|e| e[:entry_id]},
                  :select => [:title, :slug]).each do |t|
          fetched << {
            :title => t.title,
            :url => url_for(t),
            :type => "Topic"
          }
        end
      end
    end

    # .map do |i|
    #   res = {
    #     :title => i.title,
    #     :url => url_for(i.entry),
    #     :type => i.entry.class.to_s }
    #   if res[:type] == "Question"
    #     res[:topics] = i.entry.topics.map &:title
    #   elsif res[:type] == "User"
    #     res[:pic] = gravatar(i.entry.email.to_s, :size => 20)
    #   end
    #   res
    # end
    render :json => fetched.to_json
  end
end
