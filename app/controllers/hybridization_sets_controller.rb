class HybridizationSetsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections

  def new
    @hybridization_set = HybridizationSet.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @hybridization_set }
    end
  end

  def create
    @hybridization_set = HybridizationSet.new(params[:hybridization_set])

    respond_to do |format|
      if @hybridization_set.save
        flash[:notice] = 'Hybridizations were successfully created.'
        format.html { render :action => "show" }
        format.xml  { render :xml => @hybridization_set, :status => :created, :location => @hybridization_set }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @hybridization_set.errors, :status => :unprocessable_entity }
      end
    end
  end

  private

  def load_dropdown_selections
    @platforms = Platform.find(:all, :order => "name ASC")
  end

end
