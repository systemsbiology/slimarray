class BioanalyzerRunsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required, :only => [ :destroy ]
  
  def index
    @bioanalyzer_runs = BioanalyzerRun.find_for_user(current_user)
  end

  def show
    @bioanalyzer_run = BioanalyzerRun.find(params[:id])
    
    @quality_traces = QualityTrace.find( :all, :conditions => ["bioanalyzer_run_id = ?", @bioanalyzer_run.id],
                                         :order => "number ASC" )
  end

  def pdf
    bioanalyzer_run = BioanalyzerRun.find(params[:id])
    pdf = bioanalyzer_run.to_pdf

    # send file to browser
    pdf_file_name = bioanalyzer_run.name + ".pdf"
    send_data pdf.render, :filename => pdf_file_name,
                           :type => "application/pdf"
  end

  def destroy
    BioanalyzerRun.find(params[:id]).destroy

    respond_to do |format|
      format.html { redirect_to(bioanalyzer_runs_url) }
      format.xml  { head :ok }
      format.json  { head :ok }
    end
  end
  
  def grid
    bioanalyzer_runs = BioanalyzerRun.find(:all, :include => [:quality_traces]) do
      if params[:_search] == "true"
        date =~ "%#{params[:date]}%" if params[:date].present?
        bioanalyzer_run.name =~ "%#{params[:name]}%" if params[:name].present?                
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => bioanalyzer_runs.to_jqgrid_json(
      [:date, :name], 
      params[:page], params[:rows], bioanalyzer_runs.total_entries
    )
  end

end
