timeTracker.controller 'TimerCtrl', ($scope, $timeout, Redmine, Project, Ticket, DataAdapter, Message, State, Resource, Option, Log, PluginManager, Const, $modal) ->
  
  # comment charactor max
  COMMENT_MAX = 255
  # mode switching animation time [ms]
  SWITCHING_TIME = 250
  # check result
  CHECK = OK: 0, CANCEL: 1, NG: -1
  # time picker's base time
  BASE_TIME = new Date("1970/01/01 00:00:00")
  # represents 24 hours in minutes
  H24 = 1440
  # represents 1 minutes
  ONE_MINUTE = 1

  # Sync_at_every_minutes
  SYNC_MINUTES = 10

  # Application state
  $scope.state = State
  # Application data
  $scope.data = DataAdapter
  # comment objects
  $scope.comment = { text: "", maxLength: COMMENT_MAX, remain: COMMENT_MAX }
  # ticked time
  $scope.time = { min: 0, logCalled: 0, calledAt: [], notLoggedMinutes: 0 }
  # time for time-picker
  $scope.picker = { manualTime: BASE_TIME }
  # Count down time for Pomodoro mode
  $scope.countDownSec = 25 * 60 # sec
  # typeahead options
  $scope.typeaheadOptions = { highlight: true, minLength: 0 }
  # jquery-timepicker options
  $scope.timePickerOptions = null
  # keyword which inputted on search form.
  $scope.word = null
  # mode state objects
  auto = pomodoro = manual = null
  # Application options
  options = Option.getOptions()

  # localStorage.setItem('test', JSON.stringify({foo: 'foo'}))
  # console.log(JSON.parse(localStorage.getItem('test')).foo)


  ###
   Initialize.
  ###
  init = () ->
    initializeSearchform()
    initializePicker(options.stepTime)
    auto = new Auto()
    pomodoro = new Pomodoro()
    manual = new Manual()
    $scope.mode = auto
    $scope.word = DataAdapter.searchKeyword
    Option.onChanged('stepTime', initializePicker)

  ###
   Initialize search form.
  ###
  initializeSearchform = () ->
    $scope.ticketData =
      displayKey: (ticket) -> ticket.id + " " + ticket.text
      source: util.substringMatcher(DataAdapter.tasks, ['text', 'id', 'project.name'])
      templates:
        suggestion: (n) ->
          if n.type is Const.TASK_TYPE.ISSUE
            return "<div class='numbered-label'>
                      <span class='numbered-label__number'>#{n.id}</span>
                      <span class='numbered-label__label'>#{n.text}</span>
                    </div>"
          else
            return "<div class='numbered-label select-issues__project'>
                      <span class='numbered-label__number'>#{n.id}</span>
                      <span class='numbered-label__label'>#{n.text}</span>
                    </div>"
    $scope.activityData =
      displayKey: 'name'
      source: util.substringMatcher(DataAdapter.activities, ['name', 'id'])
      templates:
        suggestion: (n) -> "<div class='list'><div class='list-item'>
                              <span class='list-item__name'>#{n.name}</span>
                              <span class='list-item__description list-item__id'>#{n.id}</span>
                            </div></div>"


  ###
   Initialize time picker options.
  ###
  initializePicker = (newStep) ->
    if newStep is 60
      minTime = '01:00'
    else
      minTime = '00:' + newStep
    $scope.timePickerOptions =
      step: newStep,
      minTime: minTime
      timeFormat: 'H:i',
      show2400: true


  ###
   change post mode.
   if tracking, restore tracked time.
  ###
  $scope.changeMode = (direction) ->
    restoreSelected()
    $scope.mode.onNextMode(direction)
    $scope.mode.onChanged()


  ###
   Workaround for restore selected state on switching view.
  ###
  restoreSelected = () ->
    return if not DataAdapter.searchKeyword.task
    tmpTask = DataAdapter.searchKeyword.task
    tmpActivity = DataAdapter.searchKeyword.activity
    $timeout () ->
      DataAdapter.searchKeyword.task     = tmpTask
      DataAdapter.searchKeyword.activity = tmpActivity
    , SWITCHING_TIME / 2


  ###
   Start or End Time tracking
  ###
  $scope.clickSubmitButton = () ->
    $scope.mode.onSubmitClick()


  ###
   on timer stopped, send time entry.
  ###
  $scope.$on 'timer-stopped', (e, time) ->
    $scope.time.calledAt = [];
    $scope.mode.onTimerStopped(time)


  ###
   on timer ticked, update title.
  ###
  $scope.$on 'timer-tick', (e, time) ->
    if (not State.isAutoTracking) and (not State.isPomodoring)
      return

    currentMinutes = Math.floor(time.millis / (60000))
    if currentMinutes > $scope.time.min
      console.log('update localStorage')
      params =
        id:         DataAdapter.selectedTask.id
        minutes:     currentMinutes
        comment:    $scope.comment.text
        activityId: DataAdapter.selectedActivity.id
        type:       DataAdapter.selectedTask.type
      localStorage.setItem("log", JSON.stringify(params))

    $scope.time.min = Math.floor(time.millis / (60000))

    ### Old logic that add log at every 10 minutes
      if ($scope.time.min > 0 and $scope.time.min % SYNC_MINUTES == 0 and $scope.time.calledAt.indexOf($scope.time.min) == -1)
        $scope.time.calledAt.push($scope.time.min)
        postEntry(SYNC_MINUTES)
    ###

  ###
   send time entry.
  ###
  postEntry = (minutes) ->
    hours = Math.floor(minutes / 60 * 100) / 100 # 0.00
    minuteString = minutes+'m'
    postParam = { hours: hours , comment: $scope.comment.text, minutes: minuteString }
    PluginManager.notify(PluginManager.events.SEND_TIME_ENTRY, postParam, DataAdapter.selectedTask, $scope.mode.name)
    total = DataAdapter.selectedTask.total + postParam.hours
    DataAdapter.selectedTask.total = Math.floor(total * 100) / 100
    conf =
      id:         DataAdapter.selectedTask.id
      hours:      postParam.minutes
      comment:    postParam.comment
      activityId: DataAdapter.selectedActivity.id
      type:       DataAdapter.selectedTask.type
    console.log('conf', conf)
    url = DataAdapter.selectedTask.url
    account = DataAdapter.getAccount(url)
    Redmine.get(account).submitTime(conf, submitSuccess, submitError(conf))
    console.log("string", Resource.string("msgSubmitTimeEntry", [DataAdapter.selectedTask.text, util.formatMinutes(minutes)]))
    Message.toast Resource.string("msgSubmitTimeEntry", [DataAdapter.selectedTask.text, util.formatMinutes(minutes)])

  ###
    Add log from storage
  ###
  addLog = (params) ->
    minutes = params.minutes+'m'
    conf =
      id:         params.id
      hours:      minutes
      comment:    params.comment
      activityId: params.activityId
      type:       params.type
    console.log('conf', conf)
    url = DataAdapter.selectedTask.url
    account = DataAdapter.getAccount(url)
    Redmine.get(account).submitTime(conf, submitSuccess, submitError(conf))
    Message.toast Resource.string("msgSubmitTimeEntry", ["for task #"+params.id, util.formatMinutes(params.minutes)])

  ###
   check time entry before starting track.
  ###
  preCheck = () ->
    if not DataAdapter.selectedTask
      Message.toast Resource.string("msgSelectTicket"), 2000
      return CHECK.NG
    if not DataAdapter.selectedActivity
      Message.toast Resource.string("msgSelectActivity"), 2000
      return CHECK.NG
    return CHECK.OK


  ###
   check time entry.
  ###
  checkEntry = (min) ->
    return if preCheck() isnt CHECK.OK
    if $scope.comment.remain < 0
      Message.toast Resource.string("msgCommentTooLong"), 2000
      return CHECK.NG
    if min < ONE_MINUTE
      Message.toast Resource.string("msgShortTime"), 2000
      return CHECK.CANCEL
    return CHECK.OK


  ###
   show success message.
  ###
  submitSuccess = (msg, status) ->
    if msg?.time_entry?.id?
      $scope.time.logCalled = $scope.time.logCalled++;
      PluginManager.notify(PluginManager.events.SENDED_TIME_ENTRY,  msg.time_entry, status, DataAdapter.selectedTask, $scope.mode.name)
      Message.toast Resource.string("msgSubmitTimeSuccess")
      localStorage.clear()
    else
      submitError(msg, status)


  ###
   show failed message.
  ###
  submitError = (conf) -> (msg, status) ->
    PluginManager.notify(PluginManager.events.SENDED_TIME_ENTRY, msg, status, DataAdapter.selectedTask, $scope.mode.name)
    Message.toast(Resource.string("msgSubmitTimeFail") + Resource.string("status", status), 3000)
    Log.warn conf

  ###
    Check comment
  ###
  checkComment = () ->
    if $scope.comment.text == ""
      # alert("Please add comment first")
      Message.toast("Please add comment first", 3000)
      ###
        $modal.open(
          animation: true,
          controller: "TimerCtrl",
          # template: "<span>Test</span>",
          templateUrl: "myModalContent.html",
          size: "sm"
        )
      ###
      return false
    else
      return true


  class Auto

    name: "auto"
    trackedTime: {}

    onChanged: () =>
      if State.isAutoTracking
        $timeout () => # wait for complete switching
          $scope.$broadcast 'timer-start', new Date() - @trackedTime.millis
        , SWITCHING_TIME

    onNextMode: (direction) =>
      if State.isAutoTracking
        $scope.$broadcast 'timer-stop'
      if direction > 0
        $scope.mode = manual
      else
        $scope.mode = pomodoro

    onSubmitClick: () =>
      return if preCheck() isnt CHECK.OK
      if State.isAutoTracking
        State.isAutoTracking = false
        State.title = Resource.string("extName")
        checkResult = checkEntry($scope.time.min)
        if checkResult is CHECK.CANCEL
          $scope.$broadcast 'timer-clear'
        else if checkResult is CHECK.OK
          $scope.$broadcast 'timer-stop'
      else
        storageData = localStorage.getItem("log")
        if storageData != null
          storageData = JSON.parse(localStorage.getItem("log"))
          alertMessage = "Old log is not added yet. Adding now, please start after some seconds or minute\n
            • TaskID: "+storageData.id+"\n
            • Minutes: "+storageData.minutes+"\n
          "
          # alert(alertMessage)
          addLog(storageData)
        else
          checkCommentResult = checkComment()
          if checkCommentResult
            State.isAutoTracking = true
            State.title = "Tracking..."
            $scope.$broadcast 'timer-start'

    onTimerStopped: (time) =>
      if State.isAutoTracking # store temporary
        @trackedTime = time
      else
        totalMinutes = parseInt(time.days * 60 * 24 + time.hours * 60 + time.minutes)

        postEntry(totalMinutes)

        ### Old logic for 10 minutes sync
          minutes = totalMinutes % SYNC_MINUTES
          if(minutes != 0)
            postEntry(minutes)
        ###



  class Pomodoro

    name: "pomodoro"
    trackedTime: {}

    onChanged: () =>
      if State.isPomodoring
        $timeout () => # wait for complete switching
          $scope.countDownSec = @trackedTime.millis / 1000
          $scope.$broadcast 'timer-start', $scope.countDownSec
        , SWITCHING_TIME

    onNextMode: (direction) =>
      if State.isPomodoring
        $scope.$broadcast 'timer-stop'
      if direction > 0
        $scope.mode = auto
      else
        $scope.mode = manual

    onSubmitClick: () =>
      return if preCheck() isnt CHECK.OK
      if State.isPomodoring
        State.isPomodoring = false
        State.title = Resource.string("extName")
        checkResult = checkEntry(($scope.countDownSec / 60) - ($scope.time.min + 1))
        if checkResult is CHECK.CANCEL
          $scope.$broadcast 'timer-clear'
        else if checkResult is CHECK.OK
          $scope.$broadcast 'timer-stop'
      else
        State.isPomodoring = true
        State.title = "Pomodoro..."
        $scope.countDownSec = options.pomodoroTime * 60 # sec
        $scope.$broadcast 'timer-start', $scope.countDownSec

    onTimerStopped: (time) =>
      if State.isPomodoring and (time.millis > 0) # store temporary
        @trackedTime = time
      else
        State.isPomodoring = false
        State.title = Resource.string("extName")
        postEntry(Math.round(($scope.countDownSec / 60) - Math.round(time.millis / 1000 / 60)))


  class Manual

    name: "manual"
    trackedTime: {}

    onChanged: () =>
      initializePicker(options.stepTime)

    onNextMode: (direction) =>
      if direction > 0
        $scope.mode = pomodoro
      else
        $scope.mode = auto

    onSubmitClick: () =>
      diffMillis = $scope.picker.manualTime - BASE_TIME
      min = (diffMillis / 1000 / 60)
      if (min >= H24) and (min % H24 is 0) # max 24 hrs
        min = H24
      else
        min = min % H24
      checkResult = checkEntry(min)
      return if checkResult isnt CHECK.OK
      postEntry(min)

    onTimerStopped: (time) =>
      # nothing to do


  ###
   Start Initialize.
  ###
  init()

