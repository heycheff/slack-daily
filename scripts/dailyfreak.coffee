Strings = require '../assets/strings'

USER_BLACKLIST = [
  'slackbot'
  'dailyfreak'
]

class ScrumMaster

  constructor: (@robot) ->
    @robot.hear /daily time/i, (res) =>
      @res = res
      res.send res.random Strings.dailyCalledEarly
      @startDaily()

    @robot.hear /./, (res) =>
      if res.message.user.id == @user.id
        clearTimeout(@timeoutId)

    @robot.hear /next/i, (res) =>
      if res.message.user.id == @user.id
        @res = res
        @callNextUser()

  startDaily:  ->
    @users = (user for _, user of @robot.brain.data.users when !user.slack.deleted && user.name not in USER_BLACKLIST)
    @missedUsers = []
    @user = null
    @res.send @res.random Strings.dailyStart
    @callNextUser()

  callNextUser: ->
    if @users.length == 0
      return @finishDaily()

    @timeoutId = setTimeout ( =>
      @userTimedOut()
    ), 3 * 60 * 1000

    previousUser = @user
    @user = @users.splice(Math.floor(Math.random() * @users.length), 1)[0]
    userCallString = @res.random(Strings.userCall).replace('%USER_NAME%', @user.name)

    if previousUser
      @res.send(@res.random(Strings.userFinished).replace('%USER_NAME%', previousUser.name) + userCallString)
    else
      @res.send userCallString

  userTimedOut: ->
    @missedUsers.push @user
    @res.send(@res.random(Strings.userTimedOut).replace('%USER_NAME%', @user.name))
    @callNextUser()

  finishDaily: ->
    if @missedUsers.length == 0
      @res.send @res.random Strings.successfullDailyFinish
    else
      @res.send @res.random Strings.dailyFinish
      usersNames = @missedUsers.splice(-1, 1)[0].name
      if @missedUsers.length > 0
        usersNames = @missedUsers.map((user) -> user.name).join(', ') + ' and ' + usersNames
      @res.send(@res.random(Strings.missingUsersCall).replace('%USERS_NAMES%', usersNames))

module.exports = (robot) ->
  new ScrumMaster robot
