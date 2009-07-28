class HybridizationsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  before_filter :load_dropdown_choices, :only => [:index, :new, :add, :create, :edit]

  def index
    @hybridizations = Hybridization.find(
      :all,
      :order => "hybridization_date DESC, chip_number ASC",
      :include => { :sample => :project }
    )
  end

  def new
    @available_samples = Sample.find(:all, :conditions => [ "status = 'submitted'" ],
                                     :order => "id ASC")
  
    # clear out hybridization record since this is a 'new' set
    session[:hybridizations] = Array.new
    session[:hybridization_number] = nil
  
    @submit_hybridizations = SubmitHybridizations.new
  end

  def add
    @available_samples = Sample.available_to_hybridize
    selected_samples = Sample.find_selected(params[:selected_samples], @available_samples)

    @hybridizations = session[:hybridizations]
    
    submit_hybridizations = SubmitHybridizations.new(params[:submit_hybridizations])

    current_hyb_number = session[:hybridization_number]
    current_hyb_number = current_hyb_number ||
      Hybridization.highest_chip_number(submit_hybridizations.hybridization_date)

    # only add more hyb slots if that's what was asked
    if(submit_hybridizations.valid?) 
      @hybridizations.concat(
        submit_hybridizations.hybridizations_for_selected_samples(selected_samples, current_hyb_number)
      )

      session[:hybridizations] = @hybridizations
      session[:hybridization_number] = current_hyb_number
    end

    
    @available_samples = Sample.available_to_hybridize(@hybridizations)
  end
  
  def order_hybridizations
    @order = params[:hybridization_list]
    @hybridizations = session[:hybridizations]

    # re-number hybridizations
    for n in 0..@hybridizations.size-1
      @hybridizations[@order[n].to_i-1].chip_number = n+1
    end
    @hybridizations.sort! {|x,y| x.chip_number <=> y.chip_number }

    session[:hybridizations] = @hybridizations
    render :partial => 'hybridization_list'
  end
  
  def create
    @hybridizations = session[:hybridizations]

    failed = false 
    for hybridization in @hybridizations
      # if any one hybridization record isn't valid,
      # we don't want to save any
      if !hybridization.valid?
        failed = true
      end
    end
    if failed
      @submit_hybridizations = SubmitHybridizations.new
      @available_samples = Sample.find(:all, :conditions => [ "status = 'submitted'" ],
                                       :order => "submission_date DESC")
      render :action => 'add'
    else
      # save now that all hybridizations have been tested as valid
      for hybridization in @hybridizations
        hybridization.save
        
        # mark sample as hybridized
        hybridization.sample.update_attributes(:status => 'hybridized')
      end
      flash[:notice] = "Hybridization records"
      if SiteConfig.track_inventory?
        # add chip transactions for these hybridizations
        Hybridization.record_as_chip_transactions(@hybridizations)
        flash[:notice] += ", inventory changes"
      end
      if SiteConfig.create_gcos_files?
        begin    
          # output files for automated sample/experiment loading into GCOS
          @hybridizations.each do |h|
            h.create_gcos_import_file
          end
          flash[:notice] += ", GCOS files"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write GCOS file(s) to " + SiteConfig.gcos_output_path + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end      
      end
      if SiteConfig.create_agcc_files?
        begin
          # output files for automated sample/experiment loading into GCOS
          @hybridizations.each do |h|
            h.create_agcc_array_file
          end
          flash[:notice] += ", AGCC files"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write AGCC file(s) to " + SiteConfig.agcc_output_path + ". " +
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      end
      if SiteConfig.track_charges?
        # record charges incurred from these hybridizations
        record_charges(@hybridizations)
        flash[:notice] += ", charges"
      end
      if SiteConfig.using_sbeams?
        begin
          # save Bioanalyzer trace images for SBEAMS
          output_trace_images(@hybridizations)
          flash[:notice] += ", bioanalyzer images"
        rescue Errno::EACCES, Errno::ENOENT, Errno::EIO
          flash[:warning] = "Couldn't write Bioanalyzer images to " + SiteConfig.quality_trace_dropoff + ". " + 
                            "Change permissions on that folder, or choose a new output " +
                            "directory in the Site Config."
        end
      end
      # set raw_data_path for these hybridizations
      if SiteConfig.raw_data_root_path != nil && SiteConfig.raw_data_root_path != ""
        Hybridization.populate_raw_data_paths(@hybridizations)
      end
      if(flash[:notice] != nil)
        flash[:notice] += ' created successfully.'
      end
      redirect_to :action => 'show'
    end
  end
  
  def show
    if session[:hybridizations] == nil
      @hybridizations = Array.new
    else
      @hybridizations = session[:hybridizations]
    end
  end

  def clear
    new
    redirect_to :action => 'new'
  end

  def edit
    @hybridization = Hybridization.find(params[:id])
    @sample = Sample.find(@hybridization.sample_id)

    @samples = Sample.find(:all, :order => "sample_name ASC")
  end

  def update
    hybridization = Hybridization.find(params[:id])

    begin
      if hybridization.update_attributes(params[:hybridization])
        flash[:notice] = 'Hybridization was successfully updated.'
        redirect_to :action => 'list'
      else
        @samples = Sample.find(:all, :order => "sample_name ASC")
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this hybridization."
      @hybridization = Hybridization.find(params[:id])
      @sample = Sample.find(@hybridization.sample_id)
      @samples = Sample.find(:all, :order => "sample_name ASC")
      render :action => 'edit'
    end
  end

  def destroy
    hybridization = Hybridization.find(params[:id])
    sample = Sample.find(hybridization.sample_id)
    hybridization.destroy
    sample.update_attribute('status', 'submitted')
    redirect_to :action => 'list'
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
          output_trace_images(hybridizations)
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

    redirect_to :action => 'list'
  end
  
  def record_charges(hybridizations)  
    for hybridization in hybridizations
      sample = hybridization.sample
      
      template = ChargeTemplate.find(hybridization.charge_template_id)
      charge = Charge.new(:charge_set_id => hybridization.charge_set_id,
                          :date => hybridization.hybridization_date,
                          :description => sample.sample_name,
                          :chips_used => template.chips_used,
                          :chip_cost => template.chip_cost,
                          :labeling_cost => template.labeling_cost,
                          :hybridization_cost => template.hybridization_cost,
                          :qc_cost => template.qc_cost,
                          :other_cost => template.other_cost)
      charge.save
    end
  end

  def output_trace_images(hybridizations)
    for hybridization in hybridizations
      sample = hybridization.sample
      hybridization_year_month = hybridization.hybridization_date.year.to_s + ("%02d" % hybridization.hybridization_date.month)
      hybridization_date_number_string =  hybridization_year_month + ("%02d" % hybridization.hybridization_date.day) + 
                                          "_" + ("%02d" % hybridization.chip_number)
      chip_name = hybridization_date_number_string + "_" + sample.sample_name

      output_path = SiteConfig.quality_trace_dropoff + "/" + hybridization_year_month

      # output each quality trace image if it exists
      if( sample.starting_quality_trace != nil )
        copy_image_based_on_chip_name( sample.starting_quality_trace, output_path, chip_name + ".EGRAM_T.jpg" )
      end
      if( sample.amplified_quality_trace != nil )
        copy_image_based_on_chip_name( sample.amplified_quality_trace, output_path, chip_name + ".EGRAM_PF.jpg" )
      end
      if( sample.fragmented_quality_trace != nil )
        copy_image_based_on_chip_name( sample.fragmented_quality_trace, output_path, chip_name + ".EGRAM_F.jpg" )
      end
    end
  end
  
  def copy_image_based_on_chip_name(quality_trace, output_path, image_name)
    FileUtils.cp( "#{RAILS_ROOT}/public/" + quality_trace.image_path, output_path + "/" + image_name )
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
