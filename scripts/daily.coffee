module.exports = (robot) ->

  robot.hear /daily time on (.*)/i, (res) ->
    res.send 'Already?! I\'m sorry, I\'m kinda sleepy today'
    startDaily res, res.match[1]

startDaily = (res, channel) ->
  res.send 'But wait, you didn\'t teach me how!'
