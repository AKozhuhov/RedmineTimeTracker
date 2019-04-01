# Redmine Time Tracker  [![Build Status](https://travis-ci.org/ujiro99/RedmineTimeTracker.svg?branch=master)](https://travis-ci.org/ujiro99/RedmineTimeTracker) [![Build status](https://ci.appveyor.com/api/projects/status/we7rn4782lkde45i?svg=true)](https://ci.appveyor.com/project/ujiro99/redminetimetracker) [![Coverage Status](https://coveralls.io/repos/github/ujiro99/RedmineTimeTracker/badge.svg?branch=master)](https://coveralls.io/github/ujiro99/RedmineTimeTracker?branch=master)

![icon](https://github.com/ujiro99/RedmineTimeTracker/blob/master/app/images/icon_128.png)

Time tracking tool for Redmine.  
This tool works as Electron App.

## Download

Electron App

* [Release](https://github.com/hupptechnologies/RedmineTimeTracker/releases)

## Licence

MIT

## Steps

- npm install
- grunt dev
- grunt watch
- npm start

## How to build ? [ In MacOSX ]

### Windows
1. We need to install wine using brew: `brew install wine`
2. Run `npm run build:windows`

### Linux
1. Need to install fpm for making linux build on MacOSX.
2. Run `brew install gnu-tar`
3. Run `gem install --no-ri --no-rdoc fpm`
4. Run `npm run build:linux`

### Macos
1. Run `npm run build:mac`

## Change Log

### 30 March 2019
1. Removed Option of Pomodoro tracker and Manual Tracking
2. Changed time logging behavior to log every 10 minutes instead of only on stop button.

### 01 April 2019
1. Accurate log time for 10 minutes sync.