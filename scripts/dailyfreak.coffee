# Description:
#   Starts a virtual daily meeting
#

Strings = require '../assets/strings'

wakeUp = process.env.HUBOT_WAKE_UP or 'daily time'
wakeUpPath = process.env.HUBOT_WAKE_UP_PATH or '/hubot/daily'
next = process.env.HUBOT_NEXT or 'next'
skip = process.env.HUBOT_SKIP or 'skip (.+)'
channelName = process.env.HUBOT_DAILY_CHANNEL_NAME or 'daily-review'
usersBlacklist = process.env.HUBOT_DAILY_USERS_BLACKLIST or 'slackbot,dailyfreak'
daysBlacklist = process.env.HUBOT_DAILY_DAYS_BLACKLIST or '0,6'

usersBlacklist = usersBlacklist.split(',')
daysBlacklist = daysBlacklist.split(',').map (day) -> return parseInt(day)

class ScrumMaster

  constructor: (@robot) ->
    @robot.hear new RegExp(wakeUp, 'i'), (res) =>
      @sendMessage Strings.dailyCalledEarly
      @startDaily()

    @robot.hear /./, (res) =>
      if @user && res.message.user.id == @user.id
        @answered = true

    @robot.hear new RegExp(next, 'i'), (res) =>
      if res.message.user.id == @user.id
        clearTimeout(@timeoutId)
        @callNextUser()
      else
        @sendMessage Strings.skipUserAlert, userName: @user.name

    @robot.hear new RegExp(skip, 'i'), (res) =>
      if res.match[1] == @user.name
        clearTimeout(@timeoutId)
        @missedUsers.push @user
        @sendMessage Strings.userSkipped, userName: @user.name
        @callNextUser()

    @robot.router.get wakeUpPath, (req, res) =>
      return if new Date().getDay() in daysBlacklist
      @startDaily()
      res.send ok: true

  sendMessage: (messages, data) ->
    message = messages[Math.floor(Math.random() * messages.length)]
    for key, value of data
      message = message.replace(new RegExp("%#{key}%", 'g'), value)
    @robot.send room: channelName, message

  startDaily:  ->
    @users = (user for _, user of @robot.brain.data.users when !user.slack.deleted && user.name not in usersBlacklist)
    @missedUsers = []
    @user = null
    @sendMessage Strings.dailyStart
    @callNextUser()

  callNextUser: ->
    if @users.length == 0
      return @finishDaily()

    @timeoutId = setTimeout ( =>
      @userTimedOut()
    ), 3 * 60 * 1000

    previousUser = @user
    @user = @users.splice(Math.floor(Math.random() * @users.length), 1)[0]
    @answered = false

    if previousUser
      @sendMessage Strings.userFinished, userName: previousUser.name
      @sendMessage Strings.userCall, userName: @user.name
    else
      @sendMessage Strings.userCall, userName: @user.name

  userTimedOut: ->
    if !@answered
      @missedUsers.push @user
      @sendMessage Strings.userTimedOut, userName: @user.name

    @callNextUser()

  finishDaily: ->
    if @missedUsers.length == 0
      @sendMessage Strings.successfullDailyFinish
    else
      @sendMessage Strings.dailyFinish
      usersNames = @missedUsers.splice(-1, 1)[0].name
      if @missedUsers.length > 0
        usersNames = @missedUsers.map((user) -> user.name).join(', ') + ' and ' + usersNames
      @sendMessage Strings.missingUsersCall, usersNames: usersNames

module.exports = (robot) ->
  new ScrumMaster robot
