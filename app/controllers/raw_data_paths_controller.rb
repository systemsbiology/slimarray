class RawDataPathsController < ApplicationController
  before_filter :staff_or_admin_required

  def create
    @microarray = Microarray.find(
      :first,
      :include => :chip,
      :conditions => [ "chips.name = ? AND microarrays.array_number = ?",
                       params[:chip_name], params[:array_number] ]
    )

    respond_to do |format|
      if @microarray
        @microarray.update_attributes(:raw_data_path => params[:path])
        format.xml  { render :xml => @microarray, :status => :created }
        format.json  { render :json => @microarray, :status => :created }
      else
        format.xml  { render :xml => "No matching microarray found", :status => 404 }
        format.json  { render :json => "No matching microarray found", :status => 404 }
      end
    end
  end

end
