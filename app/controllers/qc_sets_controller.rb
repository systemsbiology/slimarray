class QcSetsController < ApplicationController
  before_filter :staff_or_admin_required

  def create
    #hybridization = Hybridization.find(
    #  :first,
    #  :include => {:microarray => :chip},
    #  :conditions => [ "chips.name = ? AND microarrays.array_number = ?",
    #                   params[:chip_name], params[:array_number] ]
    #)

    @qc_set = QcSet.new(
      :chip_name => params[:chip_name],
      :array_number => params[:array_number],
      :file => params[:file],
      :statistics => params[:statistics]
    )

    respond_to do |format|
      if @qc_set.save
        format.xml  { render :xml => @qc_set, :status => :created, :location => @qc_set }
        format.json  { render :json => @qc_set, :status => :created, :location => @qc_set }
      else
        format.xml  { render :xml => @qc_set.errors, :status => 422 }
        format.json  { render :json => @qc_set.errors, :status => 422 }
      end
    end
  end

end
