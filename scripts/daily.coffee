USER_BLACKLIST = [
  'slackbot'
  'dailyfreak'
]

class ScrumMaster

  constructor: (@robot) ->
    @robot.hear /daily time/i, (res) =>
      res.send 'Already?! I\'m sorry, I\'m kinda sleepy today'
      @startDaily(res)

  startDaily: (res) ->
    users = (user for _, user of @robot.brain.data.users when !user.slack.deleted && user.name not in USER_BLACKLIST)

    res.send "Shall we get started?"
    res.send user.name for user in users

module.exports = (robot) ->
  new ScrumMaster robot
