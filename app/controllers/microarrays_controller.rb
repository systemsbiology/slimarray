class MicroarraysController < ApplicationController
  before_filter :login_required

  def index
    @microarrays = Microarray.custom_find(current_user, params)

    respond_to do |format|
      format.xml   { render :xml => @microarrays.
        collect{|x| x.summary_hash(params[:with]) }
      }
      format.json  { render :json => @microarrays.
        collect{|x| x.summary_hash(params[:with]) }.to_json 
      }
    end
  end

end
