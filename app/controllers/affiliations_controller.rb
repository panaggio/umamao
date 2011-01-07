class AffiliationsController < ApplicationController
  def create
    email = params[:affiliation][:email]
    u = University.find_id_by_email_domain(email)
    
    #Verifications
    if u == nil then #if 0
      @waiting_user = WaitingUser.new
      @waiting_user.safe_update(%w[email],params[:affiliation])
      if @waiting_user.save then
	    flash[:notice] = t("email_sent",
						  :scope => "affiliations.create")
	  else
	    flash[:error] = t("users.create.flash_error")
	  end             
    else #if 0
      @affiliation = Affiliation.new
      @affiliation.safe_update(%w[email],params[:affiliation]) 
      @affiliation.university_id = u
    
      if @affiliation && @affiliation.save && @affiliation.errors.empty? then
      #if 1
        flash[:notice]  = t("email_sent", :scope => "affiliations.create")
    
      else #if 1
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
    end #if 0
    
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


