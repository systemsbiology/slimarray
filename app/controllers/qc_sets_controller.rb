class QcSetsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  # GET /qc_sets/1.xml
  # GET /qc_sets/1.json
  def show
    @qc_set = QcSet.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @qc_set }
      format.json  { render :json => @qc_set }
    end
  end

  # POST /qc_sets.xml
  # POST /qc_sets.json
  def create
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
