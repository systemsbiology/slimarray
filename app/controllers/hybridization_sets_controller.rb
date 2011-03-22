class HybridizationSetsController < ApplicationController
  before_filter :login_required

  def new
    @chips = Array.new

    current_chip_number = 1
    params["chips"].sort.each do |id, selected|
      if selected == "1"
        chip = Chip.find(id)
        if chip.sample_set.chip_type.platform.uses_chip_numbers
          chip.update_attributes(:chip_number => current_chip_number)
          current_chip_number += 1
        end
        @chips << chip
      end
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

end
