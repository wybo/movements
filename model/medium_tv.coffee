class MM.MediumTV extends MM.MediumGenericBroadcast
  setup: ->
    super

  step: ->
    for agent in @agents
      if u.randomInt(3) == 1
        @newReport(agent)
      else
        agent.watchTV()

    @drawAll()

  use: (original) ->
    agent = @createAgent(original)
    agent.watchTV = ->
      agent.read(@channel[0])

  drawAll: ->
    @copyOriginalColors()
    @resetPatches()

    channelStep = Math.floor(@world.max.x / (@channels.length + 1))

    x_offset = channelStep
    for channel, i in @channels
      report = channel[0]
      if report
        for agent, j in report.readers
          k = j - 1

          if j == 0
            agent.moveTo x: x_offset, y: 0
          else
            column_nr = Math.floor(k / (@world.max.y + 1))
            agent.moveTo x: x_offset - column_nr - 1, y: k % (@world.max.y + 1)

      for report, j in channel
        patch = @patches.patch(x: x_offset, y: j)
        @colorPatch(patch, report)

      x_offset += channelStep
