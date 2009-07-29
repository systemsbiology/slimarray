class HybridizationSetsController < ApplicationController
  before_filter :login_required
  before_filter :load_dropdown_selections

  def new
    @available_samples = Sample.find(:all, :conditions => [ "status = 'submitted'" ],
                                     :order => "id ASC")

    # clear out hybridization record since this is a 'new' set
    session[:hybridizations] = Array.new
    session[:hybridization_number] = nil

    @hybridization_set = HybridizationSet.new
  end

  def add
    @hybridization_set = HybridizationSet.new(params[:hybridization_set])
    
    @hybridizations = session[:hybridizations] || Array.new
    @available_samples = Sample.available_to_hybridize(@hybridizations)

    last_hyb_number = session[:hybridization_number] ||
      Hybridization.highest_chip_number(@hybridization_set.date)

    # only add more hyb slots if that's what was asked
    if(@hybridization_set.valid?) 
      @hybridizations.concat(
        @hybridization_set.hybridizations(
          :available_samples => @available_samples,
          :last_hyb_number => last_hyb_number
        )
      )

      session[:hybridizations] = @hybridizations
      session[:hybridization_number] = last_hyb_number + @hybridization_set.number
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
  
  def clear
    new
    redirect_to :action => 'new'
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
      @hybridization_set = HybridizationSet.new
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
        Hybridization.record_charges(@hybridizations)
        flash[:notice] += ", charges"
      end
      if SiteConfig.using_sbeams?
        begin
          # save Bioanalyzer trace images for SBEAMS
          Hybridization.output_trace_images(@hybridizations)
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

  private

  def load_dropdown_selections
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
