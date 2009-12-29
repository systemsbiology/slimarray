class RawDataPathsController < ApplicationController
  before_filter :staff_or_admin_required

  def create
    @hybridization = Hybridization.find(
      :first,
      :include => {:microarray => :chip},
      :conditions => [ "chips.name = ? AND microarrays.array_number = ?",
                       params[:chip_name], params[:array_number] ]
    )

    respond_to do |format|
      if @hybridization
        @hybridization.update_attributes(:raw_data_path => params[:raw_data_path])
        format.xml  { render :xml => @hybridization, :status => :created, :location => @hybridization }
        format.json  { render :json => @hybridization, :status => :created, :location => @hybridization }
      else
        format.xml  { render :xml => "No matching hybridization found", :status => :unprocessable_entity }
        format.json  { render :json => "No matching hybridization found", :status => :unprocessable_entity }
      end
    end
  end

end
