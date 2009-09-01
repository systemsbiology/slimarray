class ChipTransactionsController < ApplicationController
  before_filter :login_required
  before_filter :staff_or_admin_required, :except => [:index, :grid]
  before_filter :get_lab_group_and_chip_type
  before_filter :populate_lab_group_and_chip_type_choices, :only => [:new, :create, :edit, :update]

  def index
    @chip_transactions = 
      ChipTransaction.find_all_in_lab_group_chip_type(@lab_group.id, @chip_type.id)
    @totals = ChipTransaction.get_chip_totals(@chip_transactions)

    respond_to do |format|
      format.html { render :action => 'list' }
      format.xml  { render :xml => @chip_transactions }
    end
  end

  def show
    @chip_transaction = ChipTransaction.find(params[:id])

    respond_to do |format|
      format.html
      format.xml { render :xml => @chip_transaction }
      format.json { render :json => @chip_transaction }
    end
  end

  def new
    @chip_transaction = ChipTransaction.new(:lab_group_id => params[:lab_group_id],
                                            :chip_type_id => params[:chip_type_id])
  end

  def create
    begin
      @chip_transaction = ChipTransaction.new(params[:chip_transaction])
      
      if @chip_transaction.save
        flash[:notice] = 'Chip transaction was successfully created.'
        redirect_to lab_group_chip_type_chip_transactions_url(@chip_transaction.lab_group, @chip_transaction.chip_type)
      else
        render :action => 'new'
      end
    rescue
      flash[:notice] = 'Item could not be saved, probably because date is incorrect.'
      redirect_to :action => 'new'
    end
  end

  def edit
    @chip_transaction = ChipTransaction.find(params[:id])
  end

  def update
    @chip_transaction = ChipTransaction.find(params[:id])

    begin
      if @chip_transaction.update_attributes(params[:chip_transaction])
        flash[:notice] = 'Chip transaction was successfully updated.'
        redirect_to lab_group_chip_type_chip_transactions_url(@chip_transaction.lab_group, @chip_transaction.chip_type)
      else
        render :action => 'edit'
      end
    rescue ActiveRecord::StaleObjectError
      flash[:warning] = "Unable to update information. Another user has modified this chip transaction."
      @chip_transaction = ChipTransaction.find(params[:id])
      render :action => 'edit'
    end
  end

  def destroy
    @chip_transaction = ChipTransaction.find(params[:id])
    @chip_transaction.destroy
    redirect_to lab_group_chip_type_chip_transactions_url(@chip_transaction.lab_group, @chip_transaction.chip_type)
  end
  
  def grid
    chip_transactions = ChipTransaction.find(:all) do
      if params[:_search] == "true"
        date         =~ "%#{params[:date]}%" if params[:date].present?
        description  =~ "%#{params[:description]}%" if params[:description].present?
        acquired     =~ "%#{params[:acquired]}%" if params[:acquired].present?
        used         =~ "%#{params[:used]}%" if params[:used].present?
        traded_sold  =~ "%#{params[:traded_sold]}%" if params[:traded_sold].present?
        borrowed_in  =~ "%#{params[:borrowed_in]}%" if params[:borrowed_in].present?
        returned_out =~ "%#{params[:returned_out]}%" if params[:returned_out].present?
        borrowed_out =~ "%#{params[:borrowed_out]}%" if params[:borrowed_out].present?
        returned_in  =~ "%#{params[:returned_in]}%" if params[:returned_in].present?
      end
      paginate :page => params[:page], :per_page => params[:rows]      
      order_by "#{params[:sidx]} #{params[:sord]}"
    end

    render :json => chip_transactions.to_jqgrid_json(
      [:date, :description, :acquired, :used, :traded_sold, :borrowed_in, :returned_out,
       :borrowed_out, :returned_in], 
      params[:page], params[:rows], chip_transactions.total_entries
    )
  end


  private

  def get_lab_group_and_chip_type
    @lab_group = LabGroup.find(params[:lab_group_id]) if params[:lab_group_id]
    @chip_type = ChipType.find(params[:chip_type_id]) if params[:chip_type_id]
  end

  def populate_lab_group_and_chip_type_choices
    @lab_groups = LabGroup.find(:all, :order => "name ASC")
    @chip_types = ChipType.find(:all, :order => "name ASC")
  end
end
