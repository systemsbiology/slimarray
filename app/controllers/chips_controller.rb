class ChipsController < ApplicationController
  before_filter :login_required

  # GET /chips/1/edit
  def edit
    @chip = Chip.find(params[:id])
    @layout = @chip.layout
    @available_samples = @chip.available_samples
  end

  # PUT /chips/1
  # PUT /chips/1.xml
  def update
    @chip = Chip.find(params[:id])
    @available_samples = @chip.available_samples
    
    begin
      respond_to do |format|
        if @chip.update_attributes(params[:chip])
          @layout = @chip.layout

          flash[:notice] = 'Chip was successfully updated.'
          format.html { render :action => "edit" }
          format.xml  { head :ok }
          format.json  { head :ok }
        else
          @layout = @chip.layout

          format.html { render :action => "edit" }
          format.xml  { render :xml => @chip.errors, :status => :unprocessable_entity }
          format.json  { render :json => @chip.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this chip."
      @chip = Chip.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    Chip.find(params[:id]).destroy
    
    respond_to do |format|
      format.html { redirect_to(root_url) }
    end
  end
end
