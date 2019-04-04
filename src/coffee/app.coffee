pf = 'electron'
if typeof chrome isnt "undefined" then pf = 'chrome'
timeTracker = angular.module('timeTracker',
  ['ui.bootstrap',
   'ui.timepicker',
   'ngRoute',
   'ngAnimate',
   'timer',
   'analytics',
   'siyfion.sfTypeahead',
   pf,
   'pascalprecht.translate'
  ])

###
timeTracker.run(($window, $rootScope) -> 
  $window.addEventListener("offline", () -> 
    console.log('offline')
  )

  $window.addEventListener("online", () -> 
    console.log('online')
  )
)
###