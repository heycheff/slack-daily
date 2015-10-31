module.exports = (robot) ->

  robot.hear /sup?/i, (res) ->
    res.send 'nothing much'
