class ServiceOptionsController < ApplicationController
  # GET /service_options
  # GET /service_options.xml
  def index
    @service_options = ServiceOption.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @service_options }
    end
  end

  # GET /service_options/1
  # GET /service_options/1.xml
  def show
    @service_option = ServiceOption.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @service_option }
    end
  end

  # GET /service_options/new
  # GET /service_options/new.xml
  def new
    @service_option = ServiceOption.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @service_option }
    end
  end

  # GET /service_options/1/edit
  def edit
    @service_option = ServiceOption.find(params[:id])
  end

  # POST /service_options
  # POST /service_options.xml
  def create
    @service_option = ServiceOption.new(params[:service_option])

    respond_to do |format|
      if @service_option.save
        flash[:notice] = 'ServiceOption was successfully created.'
        format.html { redirect_to(service_options_url) }
        format.xml  { render :xml => @service_option, :status => :created, :location => @service_option }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @service_option.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /service_options/1
  # PUT /service_options/1.xml
  def update
    @service_option = ServiceOption.find(params[:id])

    respond_to do |format|
      if @service_option.update_attributes(params[:service_option])
        flash[:notice] = 'ServiceOption was successfully updated.'
        format.html { redirect_to(service_options_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @service_option.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /service_options/1
  # DELETE /service_options/1.xml
  def destroy
    @service_option = ServiceOption.find(params[:id])
    @service_option.destroy

    respond_to do |format|
      format.html { redirect_to(service_options_url) }
      format.xml  { head :ok }
    end
  end
end
