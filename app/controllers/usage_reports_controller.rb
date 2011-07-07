class UsageReportsController < ApplicationController
  def new
  end

  def create
    report_params = params[:usage_report]

    @start_date = "#{report_params["start_date(1i)"]}-#{report_params["start_date(2i)"]}-#{report_params["start_date(3i)"]}"
    @end_date = "#{report_params["end_date(1i)"]}-#{report_params["end_date(2i)"]}-#{report_params["end_date(3i)"]}"
    @stats = ServiceOption.usage_between(@start_date, @end_date)

    render 'show'
  end

end
