class DocController < ApplicationController
  def privacy
    set_page_title(t("doc.privacy.title"))
    @document = "privacy"
    render "show", :layout => "welcome"
  end
  def tos
    set_page_title(t("doc.tos.title"))
    @document = "tos"
    render "show", :layout => "welcome"
  end
end
