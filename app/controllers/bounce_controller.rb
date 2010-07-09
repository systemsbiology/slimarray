class BounceController < ApplicationController
  before_filter :login_required

  def bounce
    cookies[:slimarray_refreshed] = "Yes"

    redirect_to params[:destination]
  end

end
