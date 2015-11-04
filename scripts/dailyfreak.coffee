Strings = require '../assets/strings'

USER_BLACKLIST = [
  'slackbot'
  'dailyfreak'
]

DAILY_CHANNEL = 'daily-review'

class ScrumMaster

  constructor: (@robot) ->
    @robot.hear /daily time/i, (res) =>
      @res = res
      @sendMessage Strings.dailyCalledEarly
      @startDaily()

    @robot.hear /./, (res) =>
      if @user && res.message.user.id == @user.id
        @answered = true

    @robot.hear /next/i, (res) =>
      if res.message.user.id == @user.id
        @res = res
        clearTimeout(@timeoutId)
        @callNextUser()

  sendMessage: (messages, data) ->
    message = messages[Math.floor(Math.random() * messages.length)]
    for key, value of data
      message = message.replace(new RegExp("%#{key}%", 'g'), value)
    @robot.send room: DAILY_CHANNEL, message

  startDaily:  ->
    @users = (user for _, user of @robot.brain.data.users when !user.slack.deleted && user.name not in USER_BLACKLIST)
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
