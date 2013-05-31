class RecurringSchedule < ActiveRecord::Base
  acts_as_paranoid

  belongs_to :enterable, polymorphic: true

  has_many :exception_dates

  attr_accessible   :active, :ends, :ends_counter, :ends_date, :enterable, :weekly_repeat_interval

  ENDING_CONDITIONS = %w(counter date)

  validates_inclusion_of :ends, in: ENDING_CONDITIONS, if: :active?

  validates_numericality_of :weekly_repeat_interval, greater_than: 0, if: :active?
  validates_numericality_of :ends_counter, greater_than: 0, if: lambda { active? && ends_on_counter? }

  validates_presence_of :weekly_repeat_interval, if: :active?

  validates_date :ends_date, if: lambda { active? && ends_on_date? }

  validates_uniqueness_of :enterable_id, scope: :enterable_type

  def active?
    !!active
  end

  def entry
    enterable
  end

  def ends_on_date?
    ends == 'date'
  end

  def ends_on_counter?
    ends == 'counter'
  end

  def start_date
    entry.starts.to_date
  end

  def start_time_of_associated_entry
    if entry.starts.kind_of?(Date) # convert it to time for date entries
      entry.starts.midnight
    else
      entry.starts
    end
  end

  def end_date
    if ends_on_counter?
      start_date + interval.to_days * (ends_counter - 1)
    elsif ends_on_date?
      ends_date.to_date
    else
      nil
    end
  end

  def range
    (start_date..end_date)
  end

  def interval
    weekly_repeat_interval.weeks
  end

  def duration
    entry.duration
  end

  def has_exception_date_in_range?(exceptions, range)
    range.to_date_range.any? { |date| not exceptions[date.to_s].nil? }
  end

  def occurrences(date_or_range)
    occurrences_date_range = date_or_range.to_range.to_date_range
    recurring_schedule_date_range = self.range.to_date_range

    exceptions = exceptions_in_range_by_date(recurring_schedule_date_range)

    occurrences = []

    date_min = recurring_schedule_date_range.min
    date_max = [recurring_schedule_date_range.max, occurrences_date_range.max].min
    each_occurrence_between(date_min, date_max) do |date|
      next if has_exception_date_in_range?(exceptions, date...date+interval)

      start_time = start_time_of_associated_entry.change(year: date.year, month: date.month, day: date.day)
      end_time = start_time + duration
      next unless (start_time..end_time).intersects_with_duration?(occurrences_date_range)

      occurrences << start_time
    end

    occurrences
  end

  def occurring?(date_or_range)
    occurrences(date_or_range).any?
  end

  private
  def exceptions_in_range_by_date(range)
    key_value_array = exception_dates.in(range).map {|exception| [exception.date.to_s, exception]}
    Hash[key_value_array]
  end

  def each_occurrence_between(date, date_end, &block)
    begin
      yield(date)
    end while (date += interval) <= date_end
  end
end