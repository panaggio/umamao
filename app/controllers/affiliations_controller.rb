class AffiliationsController < ApplicationController
  def create
    @affiliation = Affiliation.new
    @affiliation.safe_update(%w[university_id email],params[:affiliation])
    
    success = @affiliation && @affiliation.save
    if success && @affiliation.errors.empty? then
      flash[:notice]  = t("email_sent", :scope => "affiliations.create")
      respond_to do |format|
        format.js {
          render(:json => {:success => true,
                           :message => flash[:notice] }.to_json)
        }
      end
    else
      flash[:error] = ""
      #TODO: Put this somewhere else
      debugger
      case
        when @affiliation.errors[:email] != nil
          @affiliation.errors[:email].each do |e|
            case e
                when "has already been taken"
                  flash[:error] << " " << t("email_in_use",
                                      :scope => "affiliations.messages.errors")
                else
                  flash[:error] << " " << e
                end
          end
          
        else
          flash[:error] = @affiliation.errors.full_messages.join("**")
        end
      
      respond_to do |format|
        format.js {
          render(:json => {:success => false,
                           :message => flash[:error] }.to_json)
        }
      end
    end
  end
end


