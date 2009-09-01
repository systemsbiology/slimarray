class ChargeTemplatesController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  def index
    @charge_templates = ChargeTemplate.find(:all, :order => "name ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @charge_templates }
      format.json { render :json => @charge_templates }
    end
  end

  def show
    @charge_template = ChargeTemplate.find(params[:id])

    respond_to do |format|
      format.xml  { render :xml => @charge_template }
      format.json  { render :json => @charge_template }
    end
  end

  def new
    @charge_template = ChargeTemplate.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @charge_template }
      format.json  { render :json => @charge_template }
    end
  end

  def create
    @charge_template = ChargeTemplate.new(params[:charge_template])

    respond_to do |format|
      if @charge_template.save
        flash[:notice] = 'ChargeTemplate was successfully created.'
        format.html { redirect_to(charge_templates_url) }
        format.xml  { render :xml => @charge_template, :status => :created, :location => @charge_template }
        format.json  { render :json => @charge_template, :status => :created, :location => @charge_template }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @charge_template.errors, :status => :unprocessable_entity }
        format.json  { render :json => @charge_template.errors, :status => :unprocessable_entity }
      end
    end
  end

  def edit
    @charge_template = ChargeTemplate.find(params[:id])
  end

  def update
    @charge_template = ChargeTemplate.find(params[:id])

    begin
      respond_to do |format|
        if @charge_template.update_attributes(params[:charge_template])
          flash[:notice] = 'ChargeTemplate was successfully updated.'
          format.html { redirect_to(charge_templates_url) }
          format.xml  { head :ok }
          format.json  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @charge_template.errors, :status => :unprocessable_entity }
          format.json  { render :json => @charge_template.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this charge template."
      @charge_template = ChargeTemplate.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    ChargeTemplate.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to(charge_templates_url) }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end

  def grid
    charge_templates = ChargeTemplate.find(:all) do
      if params[:_search] == "true"
        name               =~ "%#{params[:name]}%" if params[:name].present?
        description        =~ "%#{params[:description]}%" if params[:description].present?
        chips_used         =~ "%#{params[:chips_used]}%" if params[:chips_used].present?
        chip_cost          =~ "%#{params[:chip_cost]}%" if params[:chip_cost].present?
        labeling_cost      =~ "%#{params[:labeling_cost]}%" if params[:labeling_cost].present?
        hybridization_cost =~ "%#{params[:hybridization_cost]}%" if params[:hybridization_cost].present?
        qc_cost            =~ "%#{params[:qc_cost]}%" if params[:qc_cost].present?
        other_cost         =~ "%#{params[:other_cost]}%" if params[:other_cost].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => charge_templates.to_jqgrid_json(
      [:name, :description, :chips_used, :chip_cost, :labeling_cost, :hybridization_cost,
       :qc_cost, :other_cost], 
      params[:page], params[:rows], charge_templates.total_entries
    )
  end

end
