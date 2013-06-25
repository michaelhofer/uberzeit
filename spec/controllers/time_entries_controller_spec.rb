# encoding: UTF-8

require 'spec_helper'

describe TimeEntriesController do
  render_views

  context 'for non-signed in users' do
    it 'redirects to login' do
      time_sheet = FactoryGirl.create(:time_sheet)
      get :new, time_sheet_id: time_sheet.id
      response.should redirect_to(new_session_path)
    end
  end

  context 'for signed-in users' do
    let(:user) { FactoryGirl.create(:user) }
    let(:time_sheet) { user.time_sheets.first }
    let(:time_entry) { FactoryGirl.create(:time_entry, time_sheet: time_sheet) }

    before do
      test_sign_in user
    end

    describe 'GET "new"' do
      it 'sets the start date if provided' do
        Timecop.freeze('2013-07-22')
        get :new, time_sheet_id: time_sheet, date: '2013-07-20'
        assigns(:time_entry).start_date.should eq('2013-07-20'.to_date)
      end
    end

    describe 'PUT "update"' do
      before do
        time_entry = FactoryGirl.create(:time_entry, time_sheet: time_sheet)
      end

      context 'with valid attributes' do
        it 'changes time_entry\'s attributes' do
          put :update, id: time_entry, time_sheet_id: time_entry.time_sheet, time_entry: {start_date: '2013-02-02', start_time: '11:00', end_time: '12:00'}
          time_entry.reload
          time_entry.starts.should eq('2013-02-02 11:00 +0100'.to_time)
          time_entry.ends.should eq('2013-02-02 12:00 +0100'.to_time)
        end

        it 'redirects to the sheet overview' do
          put :update, id: time_entry, time_sheet_id: time_entry.time_sheet, time_entry: FactoryGirl.attributes_for(:time_entry)
          response.body.should redirect_to(time_sheet_path(time_sheet))
        end

        it 'updates start and end date of the corresponding time entry' do
          put :update, id: time_entry, time_sheet_id: time_entry.time_sheet, time_entry: {start_date: '2013-02-05', start_time: '23:00', end_time: '01:00'}
          time_entry.reload
          time_entry.starts.should eq("2013-02-05 23:00 +0100".to_time)
          time_entry.ends.should eq("2013-02-06 01:00 +0100".to_time)
        end

      end

      context 'with invalid attributes' do
        it 're-renders the :edit template' do
          put :update, id: time_entry, time_sheet_id: time_entry.time_sheet, time_entry: FactoryGirl.attributes_for(:time_entry, start_time: '')
          response.body.should =~ /muss ausgefüllt werden/
        end
      end
    end

    describe 'POST "create"' do
      context 'with valid attributes' do
        let(:time_type) { TEST_TIME_TYPES[:work] }

        it 'creates a new single entry' do
          expect do
            post :create, time_sheet_id: time_sheet.id, time_entry: FactoryGirl.attributes_for(:time_entry, time_type_id: time_type)
          end.to change(TimeEntry,:count).by(1)
        end

        it 'returns empty json (no errors)' do
          post :create, time_sheet_id: time_sheet.id, time_entry: FactoryGirl.attributes_for(:time_entry, time_type_id: time_type)
          response.body.should redirect_to(time_sheet_path(time_sheet))
        end

        it 'creates a timer on the selected date' do
          Timecop.freeze('2013-07-22')
          post :create, time_sheet_id: time_sheet.id, time_entry: FactoryGirl.attributes_for(:time_entry, time_type_id: time_type, start_time: '09:00')
          assigns(:time_entry).start_date.should eq('2013-07-22'.to_date)
        end

        it 'understands a time range which spans over midnight' do
          Timecop.freeze('2013-02-02 16:00 +0100')
          post :create, time_sheet_id: time_sheet.id, time_entry: FactoryGirl.attributes_for(:time_entry, time_type_id: time_type, start_time: '23:00', end_time: '01:00', end_date: nil)
          assigns(:time_entry).start_date.should eq('2013-02-02'.to_date)
          assigns(:time_entry).end_date.should eq('2013-02-03'.to_date)
          assigns(:time_entry).duration.should eq(2.hours)
        end
      end

      context 'with invalid attributes' do
        it 'does not save the new single entry' do
          expect { post :create, time_sheet_id: time_sheet.id, time_entry: FactoryGirl.attributes_for(:invalid_time_entry) }.to_not change(TimeEntry,:count)
        end

        it 'returns json errors' do
          post :create, time_sheet_id: time_sheet.id, time_entry: FactoryGirl.attributes_for(:time_entry, start_time: '')
          response.body.should =~ /muss ausgefüllt werden/
        end
      end
    end

    describe 'DELETE "destroy"' do

      it 'deletes the entry' do
        time_entry
        expect { delete :destroy, id: time_entry, time_sheet_id: time_entry.time_sheet }.to change(TimeEntry,:count).by(-1)
      end
    end

    # describe 'PUT "exception_date"' do
    #   it 'adds the date as an exception' do
    #     recurring_schedule = time_entry.create_recurring_schedule(ends: 'date', ends_date: time_entry.starts.to_date + 1.year, weekly_repeat_interval: 1)
    #     expect { put :exception_date, id: time_entry, time_sheet_id: time_entry.time_sheet, date: Date.today }.to change(recurring_schedule.exception_dates,:count).by(1)
    #   end
    # end
  end
end
