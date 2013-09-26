# == Schema Information
#
# Table name: public_holidays
#
#  id              :integer          not null, primary key
#  start_date      :date
#  end_date        :date
#  name            :string(255)
#  first_half_day  :boolean          default(FALSE)
#  second_half_day :boolean          default(FALSE)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  deleted_at      :datetime
#

class PublicHoliday < ActiveRecord::Base
  acts_as_paranoid

  default_scope order(:date)

  attr_accessible :first_half_day, :name, :second_half_day, :date, :daypart

  validates_presence_of :name, :date

  validates_datetime :date

  scope :on, lambda { |date| date = date.to_date; { conditions: ['(date <= ? AND date >= ?)', date, date] } }
  scope :in, lambda { |range| date_range = range.to_range.to_date_range; { conditions: ['(date <= ? AND date >= ?)', date_range.max, date_range.min] } }

  after_save :update_days

  def self.in_year(year)
    scoped.in(UberZeit.year_as_range(year))
  end

  def self.half_day_on?(date)
    flag_on_date(date, :half_day?)
  end

  def self.whole_day_on?(date)
    flag_on_date(date, :whole_day?)
  end

  def whole_day?
    not half_day?
  end

  def half_day?
    first_half_day? or second_half_day?
  end
  alias_method :half_day_specific?, :half_day?

  def first_half_day?
    !!first_half_day and not !!second_half_day
  end

  def second_half_day?
    !!second_half_day and not !!first_half_day
  end

  def daypart
    case
    when whole_day?
      :whole_day
    when first_half_day?
      :first_half_day
    when second_half_day?
      :second_half_day
    end
  end

  def daypart=(value)
    case value.to_sym
    when :whole_day
      self.first_half_day = true
      self.second_half_day = true
    when :first_half_day
      self.first_half_day = true
      self.second_half_day = false
    when :second_half_day
      self.first_half_day = false
      self.second_half_day = true
    end
  end

  def on_date?(check_date)
    date == check_date
  end

  def update_days
    Day.where(date: date).each do |day|
      day.user.calculate_planned_working_time_for_date!(day.date)
    end
  end

  private
  def self.flag_on_date(date, flag_sym)
    public_holidays_on_date = on(date)

    flag = false
    public_holidays_on_date.each do |public_holiday|
      flag ||= public_holiday.send(flag_sym)
    end
    flag
  end
end
