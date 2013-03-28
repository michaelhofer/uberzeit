$ ->

  # global functions
  window.timeDiff = (start, end) ->
    diffHours = moment.duration(moment(end, 'HH:mm').diff(moment(start, 'HH:mm'))).hours()
    diffMinutes = moment.duration(moment(end, 'HH:mm').diff(moment(start, 'HH:mm'))).minutes()

    if diffHours < 0
      diffHours = 23 - diffHours * -1

    if diffMinutes < 0
      diffMinutes = diffMinutes * -1

    if diffHours < 10
      diffHours = "0#{diffHours}"

    if diffMinutes < 10
      diffMinutes = "0#{diffMinutes}"

    "#{diffHours}:#{diffMinutes}"


  window.updateTimer = ->
    if $('.timer-current').length > 0
      $('.timer-current').html(timeDiff($('.timer-current').data('start'), moment().format('HH:mm')))


  # $('#time_entry_start_date').pickadate({
  #   monthsFull: [ 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember' ],
  #   monthsShort: [ 'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun', 'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez' ],
  #   weekdaysFull: [ 'Sonntag', 'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag' ],
  #   weekdaysShort: [ 'So', 'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa' ],
  #   today: 'Heute',
  #   clear: 'Löschen',
  #   firstDay: 1,
  #   format: 'dddd, dd. mmmm yyyy',
  #   formatSubmit: 'yyyy-mm-dd'
  #   hiddenSuffix: ''
  # })


  # on page load
  updateTimer()
  if $('.timer-current').length > 0 && window.timerStarted != true
    window.timerStarted = true
    setTimeout((->
      updateTimer()
      setTimeout arguments.callee, 60000
      ), 0)

  # summary
  $('.unhider').click ->
    $('.' + $(this).data('hide-class')).hide()
    $('.' + $(this).data('unhide-class')).show()
    false

  # events
  $(document).on 'keyup', '.reveal-modal.time form #time_entry_to_time, .reveal-modal.time form #time_entry_from_time', ->
    form_id = "#" + $(this).parents('form').attr('id')
    startEl = $("#{form_id} #time_entry_from_time")
    endEl   = $("#{form_id} #time_entry_to_time")

    if endEl.val()
      $("#{form_id} #time_entry_submit").val('Add Entry')
    else
      $("#{form_id} #time_entry_submit").val('Start Timer')


    startValue = $.fn.timepicker.parseTime startEl.val()
    endValue   = $.fn.timepicker.parseTime endEl.val()

    if startValue and endValue
      start = startEl.timepicker().format(startValue)
      end   = endEl.timepicker().format(endValue)

      value = timeDiff(start, end)
    else
      value = ""

    $("#{form_id} .time-difference").html(value)

  $('.reveal-modal.time form').on 'ajax:error', (xhr, status, error) ->
    console.log xhr, status, error

  $(document).on 'ajax:success', '.reveal-modal.time form', (data, status, xhr) ->
    $(this).foundation('reveal', 'close')
    Turbolinks.visit(window.location)

  $('.stop-timer').bind 'click', ->
    $('.stop-timer i').removeClass('icon-spin')

  $('.stop-timer').bind 'ajax:complete', (xhr, status) ->
    Turbolinks.visit(window.location)

  $('.entries ul li').hover (->
    $(this).find('a.edit-time-entry-link').show()
  ), ->
    $(this).find('a.edit-time-entry-link').hide()

  $('a.edit-time-entry-link').on 'ajax:success', (xhr, data, status) ->
    $('form.edit_time_entry').remove()
    $(data).insertAfter('#edit-time-modal .row')
    $('#edit-time-modal input.time').timepicker({
      dropdown: false,
      timeFormat: 'HH:mm'
    })
    $('#edit-time-modal').foundation('reveal', 'open')

  $('li.weeksummary.overtime').hide()

  $('li.weeksummary.total').mouseenter ->
    $(this).hide()
    $('li.weeksummary.overtime').show()

  $('li.weeksummary.overtime').mouseleave ->
    $(this).hide()
    $('li.weeksummary.total').show()
