class QcThresholdsController < ApplicationController
  before_filter :load_dropdown_selections, :except => [:index, :grid, :destroy]

  # GET /qc_thresholds
  # GET /qc_thresholds.xml
  def index
    @qc_thresholds = QcThreshold.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @qc_thresholds }
    end
  end

  # GET /qc_thresholds/1
  # GET /qc_thresholds/1.xml
  def show
    @qc_threshold = QcThreshold.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @qc_threshold }
    end
  end

  # GET /qc_thresholds/new
  # GET /qc_thresholds/new.xml
  def new
    @qc_threshold = QcThreshold.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @qc_threshold }
    end
  end

  # GET /qc_thresholds/1/edit
  def edit
    @qc_threshold = QcThreshold.find(params[:id])
  end

  # POST /qc_thresholds
  # POST /qc_thresholds.xml
  def create
    @qc_threshold = QcThreshold.new(params[:qc_threshold])

    respond_to do |format|
      if @qc_threshold.save
        flash[:notice] = 'QcThreshold was successfully created.'
        format.html { redirect_to(qc_thresholds_url) }
        format.xml  { render :xml => @qc_threshold, :status => :created, :location => @qc_threshold }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @qc_threshold.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /qc_thresholds/1
  # PUT /qc_thresholds/1.xml
  def update
    @qc_threshold = QcThreshold.find(params[:id])

    respond_to do |format|
      if @qc_threshold.update_attributes(params[:qc_threshold])
        flash[:notice] = 'QcThreshold was successfully updated.'
        format.html { redirect_to(qc_thresholds_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @qc_threshold.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /qc_thresholds/1
  # DELETE /qc_thresholds/1.xml
  def destroy
    @qc_threshold = QcThreshold.find(params[:id])
    @qc_threshold.destroy

    respond_to do |format|
      format.html { redirect_to(qc_thresholds_url) }
      format.xml  { head :ok }
    end
  end

  def grid
    qc_thresholds = QcThreshold.find(:all, :include => [:platform, :qc_metric]) do
      if params[:_search] == "true"
        platform.name      =~ "%#{params["platforms.name"]}%" if params["platforms.name"].present?
        qc_metric.name     =~ "%#{params["qc_metrics.name"]}%" if params["qc_metrics.name"].present?                
        lower_limit        =~ "%#{params[:lower_limit]}%" if params[:lower_limit].present?
        upper_limit        =~ "%#{params[:upper_limit]}%" if params[:upper_limit].present?
        should_contain     =~ "%#{params[:should_contain]}%" if params[:should_contain].present?
        should_not_contain =~ "%#{params[:should_not_contain]}%" if params[:should_not_contain].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => qc_thresholds.to_jqgrid_json(
      ["platform.name","qc_metric.name",:lower_limit,:upper_limit,:should_contain,:should_not_contain], 
      params[:page], params[:rows], QcThreshold.count
    )
  end

  private

  def load_dropdown_selections
    @platforms = Platform.find(:all, :order => "name ASC")
    @qc_metrics = QcMetric.find(:all, :order => "name ASC")
  end
end
