require 'spreadsheet/excel'
include Spreadsheet

class ChargePeriodsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required
  
  def new
    @charge_period = ChargePeriod.new
  end

  def create
    @charge_period = ChargePeriod.new(params[:charge_period])
    if @charge_period.save
      flash[:notice] = 'ChargePeriod was successfully created.'
      redirect_to charge_sets_url
    else
      render :action => 'new'
    end
  end

  def edit
    @charge_period = ChargePeriod.find(params[:id])
  end

  def update
    @charge_period = ChargePeriod.find(params[:id])
    
    begin
      if @charge_period.update_attributes(params[:charge_period])
        flash[:notice] = 'ChargePeriod was successfully updated.'
        redirect_to charge_sets_url 
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this charge period."
      @charge_period = ChargePeriod.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    begin
      ChargePeriod.find(params[:id]).destroy
    rescue
      flash[:warning] = "Cannot delete charge period due to association " +
                        "with one or more charge sets."
    end
    redirect_to charge_sets_url 
  end
  
  def pdf
    period = ChargePeriod.find(params[:id])
    pdf = period.to_pdf
    
    pdf_file_name = "charges_" + period.name + ".pdf"
    send_data pdf.render, :filename => pdf_file_name,
                           :type => "application/pdf"
  end
    
  def excel
    period = ChargePeriod.find(params[:id])

    excel_file = period.to_excel
    
    send_file excel_file
  end
  
  private
  def fmt_dollars(amt)
    sprintf("$%0.2f", amt)
  end
end
