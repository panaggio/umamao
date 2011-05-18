# -*- coding: utf-8 -*-
# This controller is used to share content on other websites, such as
# posting a question or an answer on Facebook or Twitter.

# whenever this class is inherited, a constant named CONTENT_CLASS
# must be defined on the child class and set to the class that will be
# shared
# For instance, if the content is a Question, CONTENT_CLASS should be:
#
# class ShareQuestionController < ShareContentController
#   CONTENT_CLASS = Question
# end
class ShareContentController < ApplicationController
  before_filter :login_required
  before_filter :check_connections

  include ShareContentsHelper

  def new
    @content = content_class.find_by_id(params[:content])

    connections = []
    connections << "twitter" if current_user.twitter_account
    connections << "facebook" if current_user.facebook_account

    group_invitation = GroupInvitation.shared_content(
      @content, "twitter", default_message_group_invitation(@content),
      current_user)

    respond_to do |format|
      format.js do
        bitly = Bitly.new(AppConfig.bitly[:username], AppConfig.bitly[:apikey])
        html = {
          :content => @content,
          :class_name => content_class_str,
          :body => default_body,
          :where => params[:where],
          :link => {'twitter' => bitly.shorten(content_url(
            @content, :group_invitation => group_invitation.slug)).short_url},
          :connections => connections
        }
        render :json => {
          :success => true,
          :html => (render_cell :share_content, :display, html)
        }
      end
    end
  end

  def create
    @body = params[:body]
    @content = content_class.find_by_id(params[:content])

    @link = content_url(@content, :group_invitation => GroupInvitation.shared_content( @content, "facebook",
                                                                                      current_user).slug)
    status = :success

    case params[:where]
    when "facebook"
      begin
        graph = current_user.facebook_connection
        graph.put_wall_post(@body, :link => @link, :source => root_url)
        status = :success
      rescue Koala::Facebook::APIError
        status = :needs_permission
        session["omniauth_return_url"] = content_path(@content)
      end
    when "twitter"
      begin
        client = current_user.twitter_client
        client.update(@body)
        status = :success
      end
    end

    if status == :success
      message = I18n.t("#{content_class_str.pluralize}.show.share_success", :site => params[:where].capitalize)
      track_event("shared_#{content_class_str}".to_sym, :where => params[:where])
    end

    respond_to do |format|
      format.html do
        redirect_to content_path(@content)
      end

      format.js do
        case status
        when :success
          render :json => {
            :success => true,
            :message => message
          }.to_json
        when :needs_permission
          render :json => {
            :success => false,
            :status => "needs_permission",
            :html => (render_cell :external_accounts, :needs_permission,
                      :provider => params[:where])
          }.to_json
        end
      end
    end
  end

  # Check whether the corresponding external account is actually present,
  # asking the user to connect it if it isn't.
  def check_connections
    status = connection_status

    if status != :success
      respond_to do |format|
        format.js do
          case status
          when :needs_connection
            session["omniauth_return_url"] =
              content_url(content_class.find_by_id(params[:content]))
            render :json => {
              :success => false,
              :status => "needs_connection",
              :html => (render_cell :external_accounts, :needs_connection,
                        :provider => params[:where])
            }.to_json
          when :unknown_destination
            render :json => {
              :success => false,
              :message => I18n.t("#{content_class_str.pluralize}.show.unknown_destination")
            }.to_json
          end
        end
      end
    end
  end

  def connection_status
    status = :success

    case params[:where]
    when "facebook"
      if !current_user.facebook_account
        status = :needs_connection
      end
    when "twitter"
      status = :needs_connection if !current_user.twitter_client
    else
      status = :unknown_destination
    end

    status
  end

  protected
  def content_class
    self.class::CONTENT_CLASS
  end

  def content_class_str
    content_class.to_s.underscore
  end

  def content_class_sym
    content_class_str.to_sym
  end

  def content_url(content, options={})
    self.send("#{content_class_str}_url".to_sym, content, options)
  end

  def content_path(content)
    self.send("#{content_class_str}_path".to_sym, content)
  end

  # Facebook: "Is this a good question?"
  # Twitter:  "Umamão: Is this a good question? http://bit.ly/umamao"
  def default_body
    {
      'facebook' => @content.title,
      'twitter' => "#{AppConfig.application_name}: #{@content.title}"
    }
  end
end
