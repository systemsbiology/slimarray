# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
class ApplicationController < ActionController::Base
  helper :all

  # RESTful authentication
  include AuthenticatedSystem
  
  # Homebrew, very simple authorization
  include Authorization

  # Exception Notifier plugin
  include ExceptionNotifiable
  
  # filter passwords out of logs
  filter_parameter_logging "password"

  # caching help for slimcore
  include SlimcoreCaching

  def redirect_back
    redirect_to :back rescue redirect_to root_path
  end

  def rescue_action_locally(exception)
		case exception
      # deal with SLIMcore being down
      when Errno::ECONNREFUSED
        render :text => "Could not connect to SLIMcore. Ensure it is up and running, and your application.yml " +
                        "file is configured correctly."
      else
        super
		end
	end
end
