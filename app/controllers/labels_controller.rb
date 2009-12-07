class LabelsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required

  # GET /labels
  # GET /labels.xml
  def index
    @labels = Label.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @labels }
    end
  end

  # GET /labels/1
  # GET /labels/1.xml
  def show
    @label = Label.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @label }
    end
  end

  # GET /labels/new
  # GET /labels/new.xml
  def new
    @label = Label.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @label }
    end
  end

  # GET /labels/1/edit
  def edit
    @label = Label.find(params[:id])
  end

  # POST /labels
  # POST /labels.xml
  def create
    @label = Label.new(params[:label])

    respond_to do |format|
      if @label.save
        flash[:notice] = 'Label was successfully created.'
        format.html { redirect_to(labels_url) }
        format.xml  { render :xml => @label, :status => :created, :location => @label }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @label.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /labels/1
  # PUT /labels/1.xml
  def update
    @label = Label.find(params[:id])

    respond_to do |format|
      if @label.update_attributes(params[:label])
        flash[:notice] = 'Label was successfully updated.'
        format.html { redirect_to(labels_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @label.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /labels/1
  # DELETE /labels/1.xml
  def destroy
    @label = Label.find(params[:id])
    @label.destroy

    respond_to do |format|
      format.html { redirect_to(labels_url) }
      format.xml  { head :ok }
    end
  end

  def grid
    labels = Label.find(:all) do
      if params[:_search] == "true"
        name      =~ "%#{params[:name]}%" if params[:name].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => labels.to_jqgrid_json(
      [:name], 
      params[:page], params[:rows], labels.total_entries
    )
  end
end
