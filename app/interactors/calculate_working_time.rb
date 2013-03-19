class CalculateWorkingTime
  def initialize(time_sheet, date_or_range)
    @date_or_range = date_or_range
    @time_sheet = time_sheet
  end

  def total
    chunks = @time_sheet.find_chunks(@date_or_range)
    chunks.total_for_flag(:treat_as_working_time?)
  end
end
