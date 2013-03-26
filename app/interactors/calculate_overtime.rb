class CalculateOvertime

  def initialize(time_sheet, date_or_range)
    @time_sheet = time_sheet
    @user = time_sheet.user
    @date_or_range = date_or_range
  end

  def total
    total_worktime - planned_work
  end

  private
  def workload
    @workload ||= @user.workload_on(@date_or_range)
  end

  def planned_work
    @planned_work ||= @time_sheet.planned_work(@date_or_range)
  end

  def total_worktime
    @total_worktime ||= @time_sheet.work(@date_or_range)
  end

end

