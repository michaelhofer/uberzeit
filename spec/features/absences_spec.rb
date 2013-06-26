# encoding: utf-8
require 'spec_helper'

describe 'having fun with absences' do
  include RequestHelpers

  let(:user) { FactoryGirl.create(:admin) }
  let(:time_sheet) { user.current_time_sheet }

  before do
    Timecop.travel('2013-04-22 12:00:00 +0200')
    login user
  end

  it 'adds an absence', js: true do
    visit time_sheet_absences_path(time_sheet)
    click_on 'Absenz hinzufügen'
    select 'test_vacation', from: 'absence_time_type_id'
    select 'Vormittags', from: 'absence_daypart'
    click_on 'Absenz erstellen'
    find('.event-container').click
    page.should have_content('test_vacation')
    page.should have_content('22.04.2013')
  end

  it 'updates an absence', js: true do
    absence = FactoryGirl.create(:absence, start_date: '2013-04-08', end_date: '2013-04-08', time_type: :vacation, time_sheet: time_sheet)
    absence.recurring_schedule.update_attribute(:ends_date, '2013-04-08') # explicitly set recurring end date so date picker preselects correct month

    visit time_sheet_absences_path(time_sheet)

    find('.event-container').click
    click_on 'Bearbeiten'

    # popover stays open when the modal opens
    # trigger a click event to close it
    find('#absence_time_type_id').click
    find('#absence_recurring_schedule_attributes_active').click
    fill_in 'absence[recurring_schedule_attributes][weekly_repeat_interval]', with: 2


    find('#absence_recurring_schedule_attributes_ends_date').click
    find('.picker.picker--focused.picker--opened').find('div.picker__day', text: '22').click

    click_on 'Absenz aktualisieren'

    find('table', text: 'April').find('.event-container', text: '22').click
    page.should have_content('test_vacation')
    page.should have_content('Wiederholung: Alle 2 Wochen bis zum 22.04.2013')
  end

  it 'deletes an absence', js: true do
    FactoryGirl.create(:absence, start_date: '2013-04-08', end_date: '2013-04-08', time_type: :vacation, time_sheet: time_sheet)

    visit time_sheet_absences_path(time_sheet)
    find('.event-container').click
    click_on 'Bearbeiten'
    find('form').find('a', text: 'Löschen').click

    first('.event-container').should be_nil
  end
end