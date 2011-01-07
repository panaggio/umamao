class AffiliationsController < ApplicationController
  def create
    @affiliation = Affiliation.new
    @affiliation.safe_update(%w[email],params[:affiliation])
    
    u = University.find_id_by_email_domain(@affiliation[:email])
    @affiliation.university_id = u
    
    #Verifications
    if u == nil then #if-1.1
      flash[:notice] = t("email_sent",
                         :scope => "affiliations.create")
    
    elsif @affiliation && @affiliation.save && @affiliation.errors.empty? then     
      flash[:notice]  = t("email_sent", :scope => "affiliations.create")
    
    else #not necessarily an error (no_match) if-1
      #TODO: Put this somewhere else (errors module?)
      case #case 1                                     
        when @affiliation.errors[:email] != nil
          flash[:error] = ""
          @affiliation.errors[:email].each do |e|
            case e #case 2
              when "has already been taken"
                flash[:error] << " " << t("email_in_use",
                                      :scope => "affiliations.messages.errors")
              else
                  flash[:error] << " " << e
              end #case 2
          end #each do
        else #case 1
          flash[:error] = @affiliation.errors.full_messages.join("**")
        end #case 1
    end #if 1
    
    #Responding
    if !flash[:error].nil? then
		respond_to do |format|
		  format.js {
			render(:json => {:success => false,
							 :message => flash[:error] }.to_json)
		  }
		end
	elsif !flash[:notice].nil?
		respond_to do |format|
		  format.js {
			render(:json => {:success => true,
							 :message => flash[:notice] }.to_json)
		  }
        end #respond to
    end
  end #def create
end


