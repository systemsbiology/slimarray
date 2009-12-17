class HybridizationsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_choices, :only => :edit

  def index
  end

  def edit
    @hybridization = Hybridization.find(params[:id])

    @samples = Sample.find(:all, :include => :label, :order => "sample_name ASC")
  end

  def update
    @hybridization = Hybridization.find(params[:id])

    begin
      if @hybridization.update_attributes(params[:hybridization])
        flash[:notice] = 'Hybridization was successfully updated.'
        redirect_to hybridizations_url
      else
        @samples = Sample.find(:all, :include => :label, :order => "sample_name ASC")
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this hybridization."
      @samples = Sample.find(:all, :include => :label, :order => "sample_name ASC")
      render :action => 'edit'
    end
  end

  def destroy
    hybridization = Hybridization.find(params[:id])
    hybridization.destroy
    redirect_to hybridizations_url
  end

  def bulk_handler
    selected_hybridizations = params[:selected_hybridizations]

    # make an array of the hybridizations
    hybridizations = Array.new
    for hybridization_id in selected_hybridizations.keys
      if selected_hybridizations[hybridization_id] == '1'
        hybridization = Hybridization.find(hybridization_id)
        hybridizations << hybridization
      end
    end

    # make sure some hybridizations were selected--if not, complain
    if( hybridizations.size > 0 )
      # destroy, export GCOS files, or export Bioanalyzer files?
      if( params[:commit] == "Delete Hybridizations" )
        for hybridization in hybridizations
          sample = Sample.find(hybridization.sample_id)
          hybridization.destroy
          sample.update_attribute('status', 'submitted')
        end
      elsif( params[:commit] == "Export GCOS Files" )
        begin
          hybridizations.each do |h|
            h.create_gcos_import_file
          end
          flash[:notice] = "GCOS files successfully created"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write GCOS file(s) to " + SiteConfig.gcos_output_path + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      elsif( params[:commit] == "Export AGCC Files" )
        begin
          hybridizations.each do |h|
            h.create_agcc_array_file
          end
          flash[:notice] = "AGCC files successfully created"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write AGCC file(s) to " + SiteConfig.agcc_output_path + ". " +
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      elsif( params[:commit] == "Export Bioanalyzer Images" )
        begin
          Hybridization.output_trace_images(hybridizations)
          flash[:notice] = "Bioanalyzer Images output successfully"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write Bioanalyzer images to " + SiteConfig.quality_trace_dropoff + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      end
    else
      flash[:warning] = "No hybridizations were selected"
    end

    redirect_to hybridizations_url
  end
  
  def grid
    hybridizations = Hybridization.find(:all, :include => {:samples => :project}) do
      if params[:_search] == "true"
        hybridization_date   =~ "%#{params[:hybridization_date]}%" if params[:hybridization_date].present?
        chip_number          =~ "%#{params[:chip_number]}%" if params[:chip_number].present?
        samples.sample_name  =~ "%#{params["samples.sample_name"]}%" if params["samples.sample_name"].present? 
        samples.sbeams_user  =~ "%#{params["samples.sbeams_user"]}%" if params["samples.sbeams_user"].present? 
        samples.project.name =~ "%#{params["projects.name"]}%" if params["projects.name"].present?                
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => hybridizations.to_jqgrid_json(
      [:hybridization_date, :chip_number, "sample_names", "sbeams_user", "project_name"], 
      params[:page], params[:rows], hybridizations.total_entries
    )
  end

  private
  def load_dropdown_choices
    # grab SBEAMS configuration parameter here, rather than
    # grabbing it in the list view for every element displayed
    @using_sbeams = SiteConfig.find(1).using_sbeams?
  
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
    @organisms = Organism.find(:all, :order => "name ASC")

    # only show charge sets in the most recently entered charge period
    latest_charge_period = ChargePeriod.find(:first, :order => "id DESC")
    if(latest_charge_period == nil)
      @charge_sets = Array.new
    else
      @charge_sets = ChargeSet.find(:all, :conditions => [ "charge_period_id = ?", latest_charge_period.id ],
                                    :order => "name ASC")
    end
    
    # only show templates where a chip is hybridized, so chips_used > 0
    @charge_templates = ChargeTemplate.find(:all, :order => "name ASC",
                        :conditions => ["chips_used > ?", 0])
  end
end
