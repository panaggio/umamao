class DocController < ApplicationController
  def privacy
    set_page_title(t("doc.privacy.title"))
    render :layout => "welcome"
  end
  def tos
    set_page_title(t("doc.tos.title"))
    render :layout => "welcome"
  end
end
