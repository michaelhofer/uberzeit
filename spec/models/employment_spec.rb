# == Schema Information
#
# Table name: employments
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  start_date :date
#  end_date   :date
#  workload   :float            default(100.0)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  deleted_at :datetime
#

require 'spec_helper'

describe Employment do
  let(:user) { FactoryGirl.create(:user, with_employment: false) }

  it 'has a valid factory' do
    FactoryGirl.create(:employment).should be_valid
  end

  describe 'validations' do
    it 'cannot be deleted if it is the last one for the user' do
      employment = FactoryGirl.create(:employment)
      employment.destroy.should be_false
    end

    it 'cannot be saved if it overlaps with another entry' do
      existing_entry = FactoryGirl.create(:employment, start_date: '2013-05-06', end_date: '2013-05-08', user: user)
      user.reload

      new_entry = FactoryGirl.build(:employment, start_date: '2013-05-07', end_date: '2013-05-10', user: user)
      new_entry.save.should be_false
    end

    it 'cannot be saved if its an open-ended entry and there is already an existing open-ended entry' do
      existing_entry = FactoryGirl.create(:employment, start_date: '2013-05-06', end_date: nil, user: user)
      user.reload

      new_entry = FactoryGirl.build(:employment, start_date: '2013-05-07', end_date: nil, user: user)
      new_entry.save.should be_false
    end

    it 'makes sure end date if on or after start date' do
      employment = FactoryGirl.build(:employment, start_date: '2013-05-06', end_date: '2013-05-05', user: user)
      employment.should_not be_valid
    end

    it 'makes sure the workload is between 0 and 100' do
      FactoryGirl.build(:employment, workload: 0).should be_valid
      FactoryGirl.build(:employment, workload: 150).should_not be_valid
      FactoryGirl.build(:employment, workload: -5).should_not be_valid
      FactoryGirl.build(:employment, workload: 50).should be_valid
    end
  end

  context 'for multiple employments per user' do
    before do
      # create tricky employment scheme
      FactoryGirl.create(:employment, start_date: '2012-06-06', end_date: '2012-12-31', workload: 100, user: user)
      FactoryGirl.create(:employment, start_date: '2013-01-01', end_date: '2013-02-10', workload: 50, user: user)
      FactoryGirl.create(:employment, start_date: '2013-02-11', end_date: '2013-02-11', workload: 80, user: user)
      FactoryGirl.create(:employment, start_date: '2013-02-12', end_date: nil, workload: 40, user: user)
      user.reload
    end

    it 'can be deleted if there are more than one employments for the user' do
      user.employments.last.destroy.should be_true
    end

    it 'returns the employments between two dates' do
      # try to select border-line instances
      user.employments.between('2013-01-01'.to_date...'2013-02-11'.to_date).length.should eq(1)
      user.employments.between('2013-01-01'.to_date..'2013-02-11'.to_date).length.should eq(2)
      user.employments.between('2013-02-11'.to_date..'2013-02-11'.to_date).length.should eq(1)
      user.employments.between('2012-01-01'.to_date..'2014-01-01'.to_date).length.should eq(4)
    end

    it 'returns the employment for a specific date' do
      user.employments.on('2013-02-11'.to_date).workload.should eq(80)
      user.employments.on('2013-02-12'.to_date).workload.should eq(40)
    end

  end

  context 'denormalization' do

    let(:employment) { FactoryGirl.create(:employment, start_date: '2013-09-23', end_date: '2013-09-29', user: user) }

    subject { employment }

    before do
      Day.create_or_regenerate_days_for_user_and_year!(user, 2013)
    end

    it 'recalculates all the Days upon a changes' do
      subject.workload = 80
      expect { subject.save! }.to change { user.days.sum(:planned_working_time) }.from(5.work_days).to(4.work_days)
    end

    it 'recalculates also the old date when the date has been changed' do
      subject.start_date = '2013-09-24'
      expect { subject.save! }.to change { user.days.sum(:planned_working_time) }.from(5.work_days).to(4.work_days)
    end

    it 'recalculates also the old date when the date has been changed' do
      subject.end_date = '2013-09-30'
      expect { subject.save! }.to change { user.days.sum(:planned_working_time) }.from(5.work_days).to(6.work_days)
    end

    context 'open end employment' do
      let(:employment) { FactoryGirl.create(:employment, start_date: '2013-09-23', end_date: nil, user: user) }

      it 'recalculates also the old date when the date has been changed' do
        subject.start_date = '2013-09-24'
        expect { subject.save! }.to change { user.days.sum(:planned_working_time) }.from(72.work_days).to(71.work_days)
      end

      it 'recalculates also the old date when the date has been changed' do
        subject.end_date = '2013-09-30'
        expect { subject.save! }.to change { user.days.sum(:planned_working_time) }.from(72.work_days).to(6.work_days)
      end
    end

    it 'won\'t affect employments of another user' do
      another_user = FactoryGirl.create(:user, with_employment: false)
      employment_of_another_user = FactoryGirl.create(:employment, start_date: employment.start_date, end_date: employment.end_date, user: another_user)
      Day.create_or_regenerate_days_for_user_and_year!(another_user, 2013)
      expect { subject.save! }.to_not change { another_user.days.last.id }
    end

  end
end
