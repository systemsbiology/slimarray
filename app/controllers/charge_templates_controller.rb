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

end
