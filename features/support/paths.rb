module NavigationHelpers
  # Maps a name to a path. Used by the
  #
  #   When /^I go to (.+)$/ do |page_name|
  #
  # step definition in web_steps.rb
  #
  def path_to(page_name)
    case page_name

    when /the home\s?page/
      '/'

    # Add more mappings here.
    # Here is an example that pulls values out of the Regexp:
    #
    when /^(.*)'s profile page$/i
      user_path(User.find_by_name($1))

    when /^the confirmation page$/
      @confirmation_email = find_confirmation_email(@affiliation_email)
      if @confirmation_email.multipart?
        @body = @confirmation_email.parts.
          find{|part| part.content_type =~ /text\/plain/ }.body
      end
      @confirmation_path = @body.to_s[/http:\/\/[^\/]+(\S+)/, 1]
      @confirmation_path

    else
      begin
        page_name =~ /the (.*) page/
        path_components = $1.split(/\s+/)
        self.send(path_components.push('path').join('_').to_sym)
      rescue Object => e
        raise "Can't find mapping from \"#{page_name}\" to a path.\n" +
          "Now, go and add a mapping in #{__FILE__}"
      end
    end
  end
end

World(NavigationHelpers)
